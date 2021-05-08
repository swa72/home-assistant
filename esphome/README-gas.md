# Reading a gas meter

I have a pretty standard gas meter as shown on the picture below. 

<img src="../image/ems-esp.PNG">

My provider was so nice to provide me with a sensor for free. 
It's a Cyble Sensor, [specs](https://www.itron.com/-/media/feature/products/documents/brochure/cyble_sensor_brochure_gas_meter_en.pdf)
You can buy it for around 60EUR.
The sensor has two wires ("No polarity to be observed. The signal is equivalent to a dry contact signal (e.g. reed switch)."). Pulse 
duration is 35ms to 65ms, so pretty quick. 

Question remains: how do I get the data into Home Assistant? ESPHome is the answer, even for a non-hardware guy like me.

## Hardware parts
* an ESP32 (I picked a development version with a micro-USB port), ca. 7EUR
* a USB to micro-USB cable, ca. 0EUR
* an old micro-USB power supply with 5V, ca. 0EUR
* a generic breadboard, ca. 5EUR
* some wires

## Step 1: flash the ESP initially
* put the ESP32 on the breadboard
* install ESPHome add-on 
* connect the ESP32 with the USB cable to the rasperry PI (any USB port will do)
* start ESPHome add-on
  * in the ESPHome user interface on the top right, you'll find a new USB connection. If not, restart ESPHome
* create a new configuration (big "+" bottom right) that fits your ESP and flash in onto the ESP
* check if Home Assistant reports a new device

## Step 2: count the impulses
* you now have a new directory `config\esphome\` with a new yaml file that contains the configuration of the ESP
* copy all relevant parts from my [`gas3.yaml`](./gas3.yaml) to this file
  *  you may need to edit the wifi stuff (which I put into my `secrets.yaml` file) or the name of the new counter
* flash the modified file to the ESP, using "Upload"
* check if Home Assistant reports a new entity for your ESP
* disconnect the ESP from the USB
* you can do all  future update over-the-air

## Step 3: hook up the device to the meter
* connect GPIO21 pin with one cable of the Cyble sensor
* connect GND  pin with one cable of the Cyble sensor
* connect the Cyble sensor to gas meter
* connect the micro-USB power supply to the ESP

## Optional
I have added the following to my `configuration.yaml` of Home Assistant, to get aggregated data.

```
utility_meter:
  gasverbrauch_hourly:
    source: sensor.gasverbrauch
    cycle: hourly
  gasverbrauch_daily:
    source: sensor.gasverbrauch
    cycle: daily
  gasverbrauch_weekly:  
    source: sensor.gasverbrauch
    cycle: weekly
  gasverbrauch_monthly:
    source: sensor.gasverbrauch
    cycle: monthly
  gasverbrauch_yearly:
    source: sensor.gasverbrauch
    cycle: yearly
```

