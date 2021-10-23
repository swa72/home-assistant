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
  * the last step provides a description of the heating control

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
  
## Step 4: Add some thermostat controls
* `climate.thermostat_hc1` was missing, also for circuits 2 and 3

## Step 5: Advanced heating control
* As mentioned above, I complement the existing heating control. To do just that, I simply send the offset 
parameter to the thermostat to lower or raise the flow temperatures and leave the existing heating control
to do its job. I have the following automations:
  * Circuit control for each of the three circuits
    * all rooms that are relevant for a heating circuit are rated regarding their temperature (ok, too-cold, too-warm). Based on that
		information, the entire circuit is rated. If a circuit changes state from e.g. 'ok' to 'too-warm'), that circuit receives an offset of -3K.
		Offsets are not sent during the night (e.g. 2200-0500). If rooms for a given circuit get too cold, the rating for that circuit will change 
		and we still have time from 0500 to heat up.
  * Reset offsets
	  * at 23:05 all offsets are set back to zero
  * Heating forecast
    * at 23:30 the automation analyses the weather forecast. If its sunny or temperature is above 20°C, all offsets are set 
		to -3K (which lowers the target temp of each circuit by 9 degrees)
  * Heating work schedule
	  * any day, we're out of the house during work week, lower the set temp from 20°C to 19°C between 0700 and 1200
  * Monitoring
    * at night, set the heating date/time using NTP
    * if the heating shows odd maintenance codes, send notification
    * if the target temp of the underfloor heating circuit is higher than the radiator circuit, 
		change the offset of the underfloor heating circuit so that the target temp is at most that of 
		the radiator circuit. Otherwise the heating curve of the underfloor heating circuit will dominate
		the target temperature of the burner. This is particularly true during outside temperatures around 
		10°C-15°C. However, main source of heating in my house are the radiators.

## Step 6: Backup all heating settings
* ssh to ems-esp with Putty and logging enabled, issue `show`
* copy the logfile to Evernote

Next steps
  * offset also during night? maybe only -1?
  * merge reset and forecast