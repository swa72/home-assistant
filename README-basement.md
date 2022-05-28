# How to dry the basement using Home Assistant
Basic idea is to dry the basement using fans that exchange humid air in the basement with dry air from the outside.

## BOM
* Shelly Plug-S (ca. 17 EUR)
* Aqara temperature and humidity sensor (ca. 17 EUR or cheaper on aliexpress and the like)
* Vortice VARIO 150/6“ AR Q vent (ca. 110 EUR) to blow air in
* Vortice VARIO 230/9“ AR Q vent (ca. 210 EUR) to blow air out
* power cables for the two fans

## Configuration in HA
In a first step Home assistant calculates internal and external dew points ([conversion help](https://bmcnoldy.rsmas.miami.edu/Humidity.html)) based on 
* temperature and rel. humidity supplied from an Aqara Zigbee sensor in the basement and
* from an Aqara Zigbee sensor outside the house (temp in this case comes from my heating sensor outside)

I also wanted an automation that is not prone to HA restarts or automation reloads.

The following sensors do the calculation for dewpoints:
```
- platform: template
  sensors:
    rel_humidity:
      friendly_name: "Relative humidity outside"
      unit_of_measurement: "%"
      value_template: "{{ states('sensor.multi_og_aussen_humidity') | float }}"
    dewpoint_outside:
      unit_of_measurement: "°C"
      value_template: >-
        {% set h, t = states('sensor.rel_humidity') | float, states('sensor.thermostat_damped_outdoor_temperature') %}
        {% if not h or t == 'unknown' -%}
         'unknown'
        {%- else %}
        {% set t = t | float %}
        {% set h = h | float %}
        {{ (243.04*(log(h/100)+((17.625*t)/(243.04+t)))/(17.625-log(h/100)-((17.625*t)/(243.04+t))))|round(2) }}
        {% endif %}
    dewpoint_basement:
      unit_of_measurement: "°C"
      value_template: >-
        {% set h, t = states('sensor.multi_keller_gross_humidity') | float, states('sensor.multi_keller_gross_temperature') %}
        {% if not h or t == 'unknown' -%}
         'unknown'
        {%- else %}
        {% set t = t | float %}
        {% set h = h | float %}
        {{ (243.04*(log(h/100)+((17.625*t)/(243.04+t)))/(17.625-log(h/100)-((17.625*t)/(243.04+t))))|round(2) }}
        {% endif %}
```

In a second step some rules (configurable in the UI) decide whether to run the fans or not.
* run fans only during timeframe defined by `binary_sensor.dew_timeframe` (time of day helper)
* run fans if outside dewpoint is `input_number.dew_delta`°C below dewpoint in basement
* run fans for `timer.dewtimer_runfan` minutes
* after a run, wait for `timer.dewtimer_pausefan` minutes
* do not run fans if rel. humidity in basement is less than `input_number.dew_humidity_no_fan`%
* do not run fans if temperature in basement is less than `input_number.dew_temp_no_fan` °C
* do not run fans more than five times a night

So we first define a bunch of sensors to decide whether to run the fans or not.

```
    dew_delta_ok:
      value_template: "{{ states('sensor.dewpoint_basement')|float - states('sensor.dewpoint_outside')|float > states('input_number.dew_delta')|float }}"
    dew_humidity_ok:
      value_template: "{{ states('sensor.multi_keller_gross_humidity')|float > states('input_number.dew_humidity_no_fan')|float }}"
    dew_temp_ok:
      value_template: "{{ states('sensor.multi_keller_gross_temperature')|float > states('input_number.dew_temp_no_fan')|float }}"
```

And here is the automation that controls everything.
```
alias: Basement fan control with dewpoint
description: ''
trigger:
  - platform: state
    entity_id:
      - sensor.dew_delta_ok
    from: 'False'
    to: 'True'
    id: dewdeltaok
  - platform: event
    event_type: timer.finished
    event_data:
      entity_id: timer.dewtimer_runfan
    id: runfanfinished
  - platform: event
    event_type: timer.finished
    event_data:
      entity_id: timer.dewtimer_pausefan
    id: pausefanfinished
  - platform: time_pattern
    hours: '12'
    minutes: '00'
    seconds: '00'
    id: noon
  - platform: homeassistant
    event: start
    id: hastart
  - platform: event
    event_type: dew_event
    event_data:
      foo: bar
    id: waitfinished
  - platform: state
    entity_id:
      - binary_sensor.dew_timeframe
    from: 'True'
    to: 'False'
    id: timeframeend
  - platform: state
    entity_id:
      - binary_sensor.dew_timeframe
    from: 'False'
    to: 'True'
    id: timeframebegin
condition: []
action:
  - choose:
      - conditions:
          - condition: trigger
            id:
              - timeframebegin
              - dewdeltaok
              - hastart
              - waitfinished
          - condition: state
            entity_id: sensor.dew_delta_ok
            state: 'True'
          - condition: state
            entity_id: sensor.dew_humidity_ok
            state: 'True'
          - condition: state
            entity_id: sensor.dew_temp_ok
            state: 'True'
          - condition: state
            entity_id: binary_sensor.dew_timeframe
            state: 'True'
          - condition: numeric_state
            entity_id: counter.dew_index
            below: '5'
        sequence:
          - service: switch.turn_on
            data: {}
            target:
              entity_id: switch.shellys_keller_luefter1
          - service: timer.start
            data:
              duration: '{{states(''input_number.dew_duration_fan'')|int*60}}'
            target:
              entity_id: timer.dewtimer_runfan
          - service: counter.increment
            data: {}
            target:
              entity_id: counter.dew_index
      - conditions:
          - condition: trigger
            id: runfanfinished
        sequence:
          - service: switch.turn_off
            data: {}
            target:
              entity_id: switch.shellys_keller_luefter1
          - service: timer.start
            data:
              duration: '{{states(''input_number.dew_fan_wait'')|int*60}}'
            target:
              entity_id: timer.dewtimer_pausefan
      - conditions:
          - condition: trigger
            id: pausefanfinished
        sequence:
          - service: notify.persistent_notification
            data:
              message: Fan finished run {{ states('counter.dew_index') }}
          - event: dew_event
            event_data:
              foo: bar
      - conditions:
          - condition: trigger
            id: noon
        sequence:
          - service: counter.reset
            data: {}
            target:
              entity_id: counter.dew_index
      - conditions:
          - condition: trigger
            id: timeframeend
        sequence:
          - service: switch.turn_off
            data: {}
            target:
              entity_id: switch.shellys_keller_luefter1
    default:
      - service: notify.persistent_notification
        data:
          title: Fan control basement
          message: ' delta_ok {{states(''sensor.dew_delta_ok'')}} {{''\n''-}} hum_ok {{states(''sensor.dew_humidity_ok'')}} {{''\n''-}}temp_ok {{states(''sensor.dew_temp_ok'')}} {{''\n''-}}time_ok {{states(''binary_sensor.dew_timeframe'')}} {{''\n''-}}index {{states(''counter.dew_index'')}}'
mode: queued

```

The user interface to configure everything in a dashboard

```
type: entities
entities:
  - entity: binary_sensor.dew_timeframe
  - entity: input_number.dew_duration_fan
  - entity: input_number.dew_fan_wait
  - entity: input_number.dew_delta
  - entity: input_number.dew_humidity_no_fan
  - entity: input_number.dew_temp_no_fan
  - entity: sensor.dew_difference
    name: Current dew difference
  - type: divider
  - entity: sensor.dew_delta_ok
  - entity: sensor.dew_humidity_ok
  - entity: sensor.dew_temp_ok
  - entity: counter.dew_index
  - type: divider
  - entity: sensor.shellys_keller_luefter1_power
  - entity: switch.shellys_keller_luefter1
  - entity: sensor.shellys_keller_luefter1_energy
title: Lüfter Großer Keller
```

You'll find the entire code in [automations.yaml](./automations.yaml) and [sensors.yaml](./sensors.yaml). 

Additionally, you'll need some helpers (e.g. `input_number.dew_duration_fan`).
