# Problem with MQTT and "_2" entities
I have noticed a couple of times that my EMS-ESP, MQTT and HA do not play well together. In that case, HA creates numerous copies of already existing entities (you can recognize them with a "_2" postfix).
That itself would not be a problem, but new data is now only received in the new "_2" entities. However, all my dashboards, energy data or long term stats (Influx) among numerous other things depend on the old entity names. 

Here is an approach to get rid of the problem: You will remove all EMS-ESP entities (which come thru MQTT) from HA and restart the EMS-ESP device. All entities are then created automagically again. 

Just follow the following steps (you need some basic skills in Python):

* disable MQTT on the EMS-ESP
* use MQTT explorer (http://mqtt-explorer.com/), connect to HA's broker and remove everything from ```homeassistant/*/ems-esp```
* clean HA's entity registry ```.storage/core_entity_registry```, see below
* restart HA
* enabled MQTT on the EMS-ESP
* wait for data to arrive

## Clean HA's entity registry

This is not for the faint of heart as you will mess around with some of HA's internal data structures. Backup data before.

* copy ```.storage/core_entity_registry``` from your server to another place
* adapt files names (and other stuff) in the python code below and run it. It will create a new file where all relevant entities are removed
* copy the newly created file back to your server (with the name ```.storage/core_entity_registry```)


```python
# install Anaconda
# run "Anaconda Navigator"
# launch "jupyter" app
# navigate to some folder and create new python notebook
# save notebook to said folder
# hit Shift-Enter to execute code

import json
import re

# open file, must be in the same folder as the jupyter notebook
f=open('core.entity_registry')

#  returns JSON object as a dictionary
data = json.load(f)

# create a new dic
new_entities = []

# go thru all entities and add the ones that DO NOT match the regexp to the new dic
for item in data["data"]["entities"]:
# thermostat
# boiler
# mixer    
# solar    
# system
    if not re.match ("climate.thermostat_hc.*", item['entity_id']) and \
        not re.match ("number.thermostat_.*", item['entity_id']) and \
        not re.match ("select.thermostat_.*", item['entity_id']) and \
        not re.match ("sensor.id_2", item['entity_id']) and \
        not re.match ("sensor.thermostat_.*", item['entity_id']) and \
        not re.match ("switch.thermostat_.*", item['entity_id']) and \
        not re.match ("binary_sensor.boiler_.*", item['entity_id']) and \
        not re.match ("number.boiler_.*", item['entity_id']) and \
        not re.match ("select.boiler_.*", item['entity_id']) and \
        not re.match ("sensor.boiler_.*", item['entity_id']) and \
        not re.match ("sensor.id", item['entity_id']) and \
        not re.match ("switch.boiler_.*", item['entity_id']) and \
        not re.match ("binary_sensor.mixer_.*", item['entity_id']) and \
        not re.match ("number.mixer_hc.*", item['entity_id']) and \
        not re.match ("number.mixer_ww.*", item['entity_id']) and \
        not re.match ("sensor.mixer_.*", item['entity_id']) and \
        not re.match ("switch.mixer_hc.*", item['entity_id']) and \
        not re.match ("binary_sensor.solar.*", item['entity_id']) and \
        not re.match ("number.solar_.*", item['entity_id']) and \
        not re.match ("select.solar_.*", item['entity_id']) and \
        not re.match ("sensor.id_3", item['entity_id']) and \
        not re.match ("sensor.solar_.*", item['entity_id']) and \
        not re.match ("switch.solar_.*", item['entity_id']) and \
        not re.match ("binary_sensor.system_.*", item['entity_id']) and \
        not re.match ("sensor.system_.*", item['entity_id']):
            # prettyline = json.dumps(item,indent=2)
            # print(prettyline)
            new_entities.append(item)

# save new list to dictionary
data["data"]["entities"] = new_entities

# write the new file
with open('core.entity_registry-new', 'w') as outfile:
    json.dump(data, outfile, indent=2)

# clean up
f.close()
outfile.close()
```
