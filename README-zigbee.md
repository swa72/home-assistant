## Disappearing Zigbee devices
Zigbee device no longer updated in HA
* phoscon add device
* push button
* hit ok in UI
* reloading deconz integration -> no change
* restarting deconz in supervisor -> no change
* restarting HA -> worked (not sure if the previous two steps were needed)

## Changing Zigbee devices directly thru terminal window
* My integration ID is 00212E066FC0 (not used in subsequent steps) 
* See https://blog.galt.me/home-assistant-deconz-zigbee-rest-api-usage/
  * Step 0 enable REST API in phoscon app
  * Step 1 `http:/172.30.33.2:40850`
  * Step 2 `curl -X POST -d '{"devicetype": "terminal"}' http://172.30.33.2:40850/api/`
  * Step 3 `[{"success":"{username":"876C8540DA"`
  * Step 4 `curl -X GET http://172.30.33.2:40850/api/876C8540DA/sensors/5`
* Provide me with a list of all sensors
  * `curl -X GET http://172.30.33.2:40850/api/876C8540DA/sensors`

## Changing Zigbee devices directly in google chrome
* Install postman chrome extension and enable it (top right)
* run GET on `https://phoscon.de/discover` inside postman
```
[
    {
        "id": "00212EFFFF066FC0",
        "internalipaddress": "172.30.33.2",
        "macaddress": "00212EFFFF066FC0",
        "internalport": 40850,
        "name": "Phoscon-GW",
        "publicipaddress": "xx.xx.xx.xx"
    }
]
``` 
* while access from the terminal window worked, it does not from the web browser.
  * go to Supervisor | deconz | Configuration and change the line to
 ```
 Container		Host	Description
 40850/tcp		40850	deCONZ API backend (Not required for Ingress)
 ```
* not sure whether the last step was necessary
* running POST on `192.168.178.83:40850/api/`works and gives me the API key `38D7042DC3` (ip adress from the raspberry, not from the discover command)
* running GET on `http://192.168.178.83:40850/api/38D7042DC3/sensors` gives me all sensors
* copy the text file to notepad and clean it
* to rename a zigbee devices then do
  * run a PUT with `http://192.168.178.83:40850/api/38D7042DC3/sensors/2` and the request data of
  ```
{
  "name": "Haustuer"
}
  ```
  * one could also script that with `curl -H 'Content-Type: application/json' -X PUT -d '{"name": "Haustuer"}' http://192.168.178.83:40850/api/38D7042DC3/sensors/2`
* reloaded the deconz integration - no change to device name
* restarted deconz in Supervisor - no change in device name
* called both to no avail

```
service: deconz.device_refresh
data:
  bridgeid: 00212E066FC0

service: deconz.remove_orphaned_entries
data:
  bridgeid: 00212E066FC0
```

* then the cruel way ...
  * create snapshot
  * we have two file "core.device_registry" and "core.entity_registry"
  * if we rename a device with the PUT command above AND reload the integration, "core.device_registry" changes from

```
	"manufacturer": "LUMI",
	"model": "lumi.sensor_magnet.aq2",
	"name": "Kellert\u00fcr",
	"sw_version": "20161128",
	"entry_type": null,
	"id": "c7a5961847ed6ef92ee95639fa774f50",
	"via_device_id": "e1cf998483deaf99c2ded93afb32843f",
	"area_id": "keller",
	"name_by_user": "Kellert\u00fcr",
```

  to

```
	"name": "Kellertuer",
	"sw_version": "20161128",
	"entry_type": null,
	"id": "c7a5961847ed6ef92ee95639fa774f50",
	"via_device_id": "e1cf998483deaf99c2ded93afb32843f",
	"area_id": "keller",
	"name_by_user": "Kellert\u00fcr",
```

* deconz refresh or remove orphaned service will not do the trick.
* but it will not change the "name_by_user" which is the name HA shows in Configuration | Devices
* the multi sensors have one device in HA, but show up as three sensors in the REST API
  * humidity
  * temperature
  * pressure
* I have set all sensor names (see desktop\raspi\conbee-rest-api-sensors-list.txt)
* if we ever have to start from scratch/remove core.entity_registry, there should only be minor tweaks to the naming scheme

## Naming Schema
* use basically "Floor"-"Room"-"Function", e.g. "DG-Stefan-Fenster-Ost"


## IKEA repeater
* plug it in. do I need to press something?
