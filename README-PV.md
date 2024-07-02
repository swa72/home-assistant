# Intro
I have recently bought a solar system. And what could be better than have HA control the entire thing. We need ...
* EVCC add-on to control charging of my Tesla
* Huawei Solar Integration to have fancy dashboards

Note that the inverter can only have one active Modbus connection. To avoid timeouts, we connect the ensemble in the following way.
No need to install an additional proxy.

Inverter <> Dongle <> EVCC <> Huawei Solar

* `evcc.yaml` contains a section that provides a Modbus proxy
```
modbusproxy:
  - port: 5200 <- the external port of your HA server
    uri: 192.168.178.132:502 <- address and port of the inverter
```
* Huawei Solar points to EVCC's proxy 
  * `Host: homeasistant.local`
  * `Port: 5200`
  * `Slave IDs: 1`
  * `Advanced: elevate permissions [x]`

You'll find the entire code in [evcc-sanitized.yaml](./evcc-sanitized.yaml).