## Problem with MQTT
I have noticed a couple of times that my EMS-ESP, MQTT and HA do not play well together. In that case, HA creates numerous copies of already existing entities (you can recognize them with a "_2" postfix.
That itself would not be a problem, but new data is now only received in the new "_2" entities. However, all my dashboard, energy data or long term stats (Influx) depend on the old entities names.
Here is the approach to get rid of the problem.

* disabled MQTT on the EMS-ESP
* use MQTT explorere and remove everything from homeassistant/*/ems-esp
* clean '.storage/core_entity_registry'
* restart HA
* enabled MQTT on the EMS-ESP
* wait for the data to arrive

