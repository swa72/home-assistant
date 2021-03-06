# Heating control using EMS-ESP

* I have a Buderus Logamax Plus GB192i heating, a central control unit RC300 and had problems with 
overshooting temperatures in my house, particularly during sunny winter days. Additionally, I wanted
to integrate the heating to HA. I have three circuits
  * ground floor and first floor radiators
  * underfloor heating for certain rooms in the ground floor
  * second floor radiators
  * and solar-supported warm water.
* I thought about going the tado route but stumbled across https://bbqkees-electronics.nl/, which basically provides a plug-in or gateway to my heating. The gateway ...
  * plugs into the heating via its service jack
  * complements the existing EMS bus (i.a. think of it as a separate control unit)
  * integrates nicely with HA
* The basic idea is: HA monitors the house and changes parameters in the thermostat which in turn controls the heating
  * HA <-> MQTT <-> EMS-ESP <-> RC300 thermostat <-> Heating
* << to be continued >>

## Step 1: Hardware installation
* I plugged the gateway into my heating with the existing cable and somehow got a loose contact; replaced the cable with the one supplied from bbqkees and everything runs fine.
* before and after
<img src="./image/IMG-7680_.jpg" width="400">
<img src="./image/IMG-7681_.jpg" width="400">

* Having connected the gateway with the heating, the gateway powers up and provides a WLAN. You can connect to the WLAN and configure the device to 
connect to your local WLAN (don't forget to give it a static address - mine is 192.168.178.90).
* The gateway finds all connected devices on the EMS bus:
<img src="./image/ems-esp.PNG">

## Step 2: Configure MQTT
* I enabled NTP on the gateway
* I then followed the instructions on https://bbqkees-electronics.nl/wiki/gateway/home-assistant-configuration.html to integrate it into HA
* installed Mosquitto broker
  * via Supervisor | Add-on store
  * started the add-on
  * added a user ```swamq```
* enabled MQTT in the web interface of the gateway
  * Host: ```homeassistant-eth```, which is the local address of the raspberry (i.e. ```192.168.178.83```)
  * Username: see above
  * Format: ```Home Assistant```
* Apparently that was it, as MQTT immediately picked up all five devices

## Step 3: Configure entities
* Went to Configuration | Integration | MQTT and clicked on devices. For each of the five devices, click on 
  the device name and use "Add to lovelace" to add all entities.
  
## Step 4: add some thermostat controls
* `climate.thermostat_hc1` is missing, also for circuits 2 and 3
