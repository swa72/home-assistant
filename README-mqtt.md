## Problem with MQTT
I have noticed a couple of times that my EMS-ESP, MQTT and HA do not play well together. In that case, HA creates numerous copies of already existing entities (you can recognize them with a "_2" postfix.
That itself would not be a problem, but new data is now only received in the new "_2" entities. However, all my dashboard, energy data or long term stats (Influx) depend on the old entities names.
Here is an approach to get rid of the problem. You will remove all 

* disable MQTT on the EMS-ESP
* use MQTT explorer (http://mqtt-explorer.com/), connect to HA's broker and remove everything from ```homeassistant/*/ems-esp```
* clean HA's entity registry ```.storage/core_entity_registry```, see below
* restart HA
* enabled MQTT on the EMS-ESP
* wait for data to arrive

# Clean HA's entity registry
