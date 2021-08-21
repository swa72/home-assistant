## How to dry the basement using Home Assistant
Basic idea is to dry the basement using fans that exchange humid air in the basement with dry air from the outside.

In a first step Home assistant calculates internal and external dew points ([conversion help](https://bmcnoldy.rsmas.miami.edu/Humidity.html)) based on 
* temperature and rel. humidity supplied from an Aqara Zigbee sensor in the basement and
* outside temperature from my heating and rel. humidity supplied from `weather.home`

The following sensors do the calculation for outside dewpoint:

```
- platform: template
  sensors:
    rel_humidity:
      friendly_name: "Relative humidity outside based on met.no"
      unit_of_measurement: '%'
      value_template: "{{ state_attr('weather.home', 'humidity') }}"
    dewpoint_outside:
      unit_of_measurement: '°C'
      value_template: >-
       {% set h, t = states('sensor.rel_humidity') | float, states('sensor.thermostat_damped_outdoor_temperature') %}
       {% if not h or t == 'unknown' -%}
        'unknown'
       {%- else %}
       {% set t = t | float %}
       {% set h = h | float %}
       {{ (243.04*(log(h/100)+((17.625*t)/(243.04+t)))/(17.625-log(h/100)-((17.625*t)/(243.04+t))))|round(2) }}
       {% endif %}
```

In a second step some rules (configurable in the UI) decide whether to run the fans or not.
* run fans if outside dewpoint is `input_number.dew_delta`°C below dewpoint in basement
* run fans for `input_number.dew_duration_fan` minutes
* after a run, wait for `input_number.dew_fan_wait` minutes
* do not run fans if rel. humidity in basement is less than `input_number.dew_humidity_no_fan`%
* do not run fans if temperature in basement is less than `input_number.dew_temp_no_fan` °C

So we first define a bunch of sensors to decide whether to run the fans or not.

```
dewpoint_basement:
  unit_of_measurement: '°C'
  value_template: >-
   {% set h, t = states('sensor.multi_keller_gross_humidity') | float, states('sensor.multi_keller_gross_temperature') %}
   {% if not h or t == 'unknown' -%}
	'unknown'
   {%- else %}
   {% set t = t | float %}
   {% set h = h | float %}
   {{ (243.04*(log(h/100)+((17.625*t)/(243.04+t)))/(17.625-log(h/100)-((17.625*t)/(243.04+t))))|round(2) }}
   {% endif %}
dew_delta_ok:
  value_template: "{{ states('sensor.dewpoint_basement')|float - states('sensor.dewpoint_outside')|float > states('input_number.dew_delta')|float }}"
dew_humidity_ok:
  value_template: "{{ states('sensor.multi_keller_gross_humidity')|float > states('input_number.dew_humidity_no_fan')|float }}"
dew_temp_ok:
  value_template: "{{ states('sensor.multi_og_konstantin_temperature')|float > states('input_number.dew_temp_no_fan')|float }}"
dew_runfan:
  value_template: "{{ states('sensor.dew_delta_ok') == 'True' and states('sensor.dew_humidity_ok') == 'True' and states('sensor.dew_temp_ok') == 'True' }}"
``` 

Ultimately, `sensor.dew_runfan` is true, if we need to run the fans.

Running the fan itself is taken care of with a script (choose the number of runs accordingly, in this case 99).

```
dehumidify_basement:
  sequence:
  - repeat:
      while:
      - condition: state
        entity_id: sensor.dew_runfan
        state: 'True'
      - condition: template
        value_template: '{{ repeat.index <= 99 }}'
      sequence:
      - service: switch.turn_on
        target:
          entity_id: switch.shellys_keller_luefter1
      - delay: '{{ states(''input_number.dew_duration_fan'') | multiply(60) | int
          }}'
      - service: switch.turn_off
        target:
          entity_id: switch.shellys_keller_luefter1
      - delay: '{{ states(''input_number.dew_fan_wait'') | multiply(60) | int }}'
  mode: single
  alias: De-humidify basement
```

You'll find the entire code in [scripts.yaml](./scripts.yaml) and [sensors.yaml](./sensors.yaml). Additionally, you'll need some helpers (e.g. `input_number.dew_duration_fan`) and a user interface.
