# home-assistant

My first attempt at running a home automation system was a Shelly device integrated to HomeKit - worked nicely. Then I fiddled around with running https://homebridge.io/ on my Raspberry 4, moved over to https://hoobs.org/ and realized that there must be something better. Luckily I found Home Assistant.

## My goal

Have a nice and easy interface for the house on the iPad (no need for my wife and kids to access any of the Home Assistant stuff). Have an advanced interface to the house for myself.

This file is intended for me to document the quirks I had during setup and for others to learn and avoid them.

## My setup

* Router Fritz!Box 7490 with open external port 443 to the Raspberry 4 (no DynDNS on fritz.box)
* A doorbell/intercom Auerswald TFS-Universal plus directly hooked up to the Fritzbox
  * additionally the Raspberry has a USB modem attached (phone line connected to Fritzbox) and the [Phone Modem integration](https://www.home-assistant.io/integrations/modem_callerid/) signals HA when the door button was pressed
* Raspberry 4 running more or less the latest Home Assistant version
  * initially connected thru wifi, later moved to ethernet and directly connected to the Fritzbox
  * conbee USB stick to [manage ZigBee network](README-zigbee.md)
* a Tesla Gen 3 Wall Connector, so I can whether the car charges (and how much)
* [a Buderus Logamax Plus GB192i heating controlled with EMS-ESP](README-heating.md)
* [a Cyble pulse sensor that reads my gas meter with an ESP](esphome/README-gas.md)
* [an ESP8266 that reads my power meter](README-powermeter.md)
* Mitsubishi Heavy Industries (MHI) air conditioner
  * SRK25ZS-W controlled with ESP (https://github.com/ginkage/MHI-AC-Ctrl-ESPHome)
  * SRK20ZS-W controlled with ESP (https://github.com/ginkage/MHI-AC-Ctrl-ESPHome)
  * Note to myself: compile the yaml file first, then connect the device to the USB port of the ThinkPad X1 to flash it
* two fans to keep my basement dry (sort of), [controlled by dew point](README-basement.md)
* an Amazon Echo dot to announce things and play stuff from Spotify ([described below](#amazon-echo-dot-and-spotify))
* Shelly 2.5 devices control my roller shutters
* Shelly 1 device controls my garage door
* two Velux solar roller shutters (SSL SK08 0000S)
  * one Velux App Control KIG 300 controls the two roller shutters and provides an Apple HomeKit controller (which in turn provides access to HA)
* Aqara door/windows sensors, connected thru Zigbee
* Aqara temp/humidity/pressure sensors, connected thru Zigbee
* a Wifi Pool Kit from Atlas Scientific to show pool data (see https://atlas-scientific.com/kits/wi-fi-pool-kit/)
  * Note to myself for calibration
	  * flash the arduino image from the X1 Thinkpad, only change Wifi credentials in the code
		* open serial monitor on COM4 and do the calibration
		* reflash with ESPHome
* a Reolink E1 pro camera (described below)
* a Reolink RLC-511WA camera (described below)
* Regular backup to ~a samba share~ Google Drive (described below)
* Regular updates to git (described below)
* I run a bunch of add-ons, described in the following sections.

# How to access HA from the outside?

The fritzbox forwards port 443 to the Raspberry running HA.

<img src="./image/7490.jpg" width="600">

## DuckDNS

* I want to access my HA instance remotely, so I needed a DNS name and Let's Encrypt support.

```
lets_encrypt:
  accept_terms: true
  certfile: fullchain.pem
  keyfile: privkey.pem
token: ##replaceme##
domains:
  - xxx.duckdns.org
aliases: []
seconds: 300
```

## NGINX Home Assistant SSL proxy

* forwards incoming SSL traffic from Fritzbox to HA's local port 8123.

```
domain: xxx.duckdns.org
certfile: fullchain.pem
keyfile: privkey.pem
hsts: max-age=31536000; includeSubDomains
cloudflare: false
customize:
  active: false
  default: nginx_proxy_default*.conf
  servers: nginx_proxy/*.conf

Network
Container	Host	Description
443/tcp      443
80/tcp		80
```

Also make sure to include `http.yaml` in `configuration.yaml` with

```
use_x_forwarded_for: true
trusted_proxies:
  - 172.30.33.0/24
  - 127.0.0.1
  - ::1
```

Using this setup, I can access HA locally with http://homeassistant-eth:8123/ and remotely with https://xxx.duckdns.org/.
This is particularly important as local devices may not be able to use HTTPS, so I can still use HTTP locally.

# AdGuard Home 

* filters out ads and other stuff (serves as DNS-server for the Fritzbox)

```
ssl: true
certfile: fullchain.pem
keyfile: privkey.pem
```

* Helpful document - albeit only in German - see https://techbox.rocks/optimierte-einstellungen-fuer-adguard-in-kombination-mit-einer-fritzbox-und-ipv6/
* Fritzbox configuration
  * Internet | Zugangsdaten | DNS Server
    * DNSv4-Server: "Andere DNSv4-Server verwenden" set both entries to 192.168.178.83 (internal IP address of Raspberry)
	* DNSv6-Server: "Andere DNSv6-Server verwenden" set both entries to fd00::e655:56be:4b9b:fb59 (internal IPv6 address of Raspberry)
  * Heimnetzwerk > Netzwerk > Netzwerkeinstellungen > weitere Einstellungen > IPv6-Konfiguration
    * check "Unique Local Addresses (ULA) immer zuweisen"
	* ULA-Präfix manuell festlegen to fd00
	* check "Diese FRITZ!Box stellt den Standard-Internetzugang zur Verfügung" to medium
	* check DNSv6-Server auch über Router Advertisement bekanntgeben (RFC 5006) and set "Lokaler DNSv6-Server:" to fd00:0:0:0:e228:6dff:fe11:406b (internal IPv6 address of Fritzbox)
	* DHCPv6-Server im Heimnetz: DHCPv6-Server in der FRITZ!Box für das Heimnetz aktivieren: check "Nur DNS-Server zuweisen"

# DSS VoIP Notifier

* using my Fritzbox as a SIP server (HA can initiate calls and play audio stuff using tts)
* install https://github.com/sdesalve/hassio-addons/tree/master/dss_voip as a simple add-on (Supervisor | Add-on Store | ... (top right) | Repositories | add https://github.com/sdesalve/hassio-addons)
* enable tts like https://www.home-assistant.io/integrations/google_translate
```
tts:
  - platform: google_translate
    language: 'de'
    service_name: google_translate_say
    --base_url: https://xxx.duckdns.org-- # deprecated since 2022.5‚
```
* configuration (note that ```192.168.178.1``` is the IP address of my Fritzbox, and ```192.168.178.83``` is the IP address of my Raspberry
```
sip_parameters:
  caller_id_uri: 'sip:homeassistant@192.168.178.1:5060'
  realm: '*'
  username: homeassistant
  password: '<replace-me-with-digits-only>'
pjsua_custom_options: '--ip-addr=192.168.178.83'
```
* steps to do on Fritzbox:, see https://superuser.com/questions/829824/android-wont-register-sip-on-Fritzbox-router
  * log on to your Fritzbox
  * select Telefoniegeräte (phone | devices)
  * Add Phone
  * LAN/WLAN (IP Phone), named 'homeassistant'
  * enter username homeassistant, passwort ONLY digits
  * pick a number (any number will do)
  * don't accept any outside calls (not required in my case)
  * my Fritzbox registered a new device with internal number *622
* start the "DSS VoIP Notifier" add-on and check the logs
* now try calling the service like (e.g. from the "Developer Tools" section in HA)

```
- service: hassio.addon_stdin
  data_template:
	addon: 89275b70_dss_voip
	input: {"call_sip_uri":"sip:**614@192.168.178.1:5060","message_tts":"Hallo Stefan"}
```
* in the above case **614 is my internal office number
* for playing audio files (or DTMF tones), use something like
```
{"call_sip_uri":"sip:**1@192.168.178.1:5060","audio_file_url":"https://xxx.duckdns.org/local/open_door_short.mp3", "call_duration":"6"}
```
and store mp3 files in folder ```\config\www```. Note that the call is automagically ended after six seconds.

# MariaDB
* Moved from Sqlite to using this https://community.home-assistant.io/t/migrating-home-assistant-database-from-sqlite-to-mariadb/96895/23

# SSH & Web Terminal
* not to be confused with "Terminal & SSH"
* this is as special version which gives me elevated access to the Raspberry

```
ssh:
  username: hassio
  password: ''
  authorized_keys: ##replaceme##
  sftp: false
  compatibility_mode: false
  allow_agent_forwarding: false
  allow_remote_port_forwarding: false
  allow_tcp_forwarding: false
zsh: true
share_sessions: false
packages: []
init_commands: []
```

# Backup to Google Drive
* installed "Home Assistant Google Drive Backup" from Supervisors' add-ons
* working with the stock install, just disabled mariadb

# Samba share

* to be able to access and edit files on the Raspberry from a Windows machine

```
workgroup: WORKGROUP
username: ##replaceme##
password: ##replaceme##
interface: ''
allow_hosts:
  - 10.0.0.0/8
  - 172.16.0.0/12
  - 192.168.0.0/16
  - 'fe80::/10'
veto_files:
  - ._*
  - .DS_Store
  - Thumbs.db
  - icon?
  - .Trashes
compatibility_mode: false
```

# deCONZ

* to run my ZigBee devices

# HACS: Alexa Media Player

* see https://github.com/custom-components/alexa_media_player/wiki
* no "Cookie import" or "Configuration.yaml" required 
* do not forget to enter the OTP code at the end (https://www.amazon.com/a/settings/approval/addbackup)
* https://community.home-assistant.io/t/alexa-tts-announcement-from-lovelace-ui-and-without-nabu-casa-alexa-media-player/259980/7

# Amazon Echo Dot and Spotify

* see above for the Alexa Media Player stuff
* to connect Spotify, I followed the stock description at https://www.home-assistant.io/integrations/spotify/ 
* I could not connect to Spotify using https as Redirect URI, my Redirect URI is `http://192.168.178.83:8123/auth/external/callback` and I also added one user under Users and Access (my spotify login).
* Before using the Echo Dot as a device for spotify, you have to run

```
alias: Spotify setup
description: ''
trigger:
  - platform: homeassistant
    event: start
condition: []
action:
  - service: media_player.select_source
    target:
      entity_id: media_player.spotify_swa72
    data:
      source: Stefans Echo Dot
mode: single
```

Note that `spotify_swa72` is my media player. You can simply add another media player to lovelace. Or use a script to play a certain playlist 

```
alias: Spotify play playlist
sequence:
  - service: media_player.play_media
    data:
      media_content_id: >-
        https://open.spotify.com/playlist/37i9dQZF1DXaIrEwuQ3hyy?si=887717bbbc1f46e9
      media_content_type: playlist
    target:
      entity_id: media_player.spotify_swa72
mode: single
```

# motionEye

* an old iPhone serving as a guinea pig camera
* for motionEye's webhooks I had to install NGINX as add-on (see https://community.home-assistant.io/t/motioneye-integration/194350/42)
* triggers action if motion is detected 

# Reolink E1 pro camera
* on IP `192.168.178.75`; access to the internet normally blocked by the router
* motionEye add-on

  ```
  motion_webcontrol: true
  ssl: true
  certfile: fullchain.pem
  keyfile: privkey.pem
  action_buttons: []
  ```
* Now to the tricky part: the latency. To avoid that, I integrate the Reolink camera with the normal camera integration like that

  ```
  - platform: mjpeg
    name: melivingroom
    still_image_url: !secret melivingroom_still_image_url
    mjpeg_url: "http://homeassistant:8082/mjpeg"
  ```

* The stream is in turn provided by motionEye (see configuration of the camera, section "Video Streaming")
  <img src="./image/motioneye.png" width="400">
* to get the PTZ controls of the camera to work, I integrated the camera also thru the ONVIF integration
* snapshots are located under `\\192.168.178.83\share\motioneye\Camera2`


# Reolink RLC-511WA camera
* on IP `192.168.178.32`; access to the internet normally blocked by the router
* integrated using https://github.com/fwestenberg/reolink_dev/
  * provides switches to turn functions on and off
  * the key for me to get motion detection running, was to make sure that I could access HA locally with HTTP
  * make sure that the camera has a normal user (not just admin)
  * make sure that http and ONVIF are enabled in network settings 
  
* processing the image is done thru motioneye like above
  * the camera has two streams
    * Clear (high-res) at 2560x1920, 20 fps, 4096, 2
    * Fluent (low-res) at 640x480, 10fps, 256, 4
  * motioneye is configured
    * `rtsp://192.168.178.32:554/h264Preview_01_sub` at 640x480, 10fps
    * section "Video streaming" at 10fps, 100%, Off, 8083, disabled, off

# ftp add-on
* to receive images and movies from the RLC-511WA camera, I've setup the ftp add-on

```
port: 21
data_port: 20
banner: Welcome to the Hass.io FTP service.
pasv: true
pasv_min_port: 30000
pasv_max_port: 30010
pasv_address: ''
ssl: false
certfile: fullchain.pem
keyfile: privkey.pem
implicit_ssl: false
max_clients: 5
users:
  - username: camera
    password: ## some password ##
    allow_chmod: false
    allow_download: false
    allow_upload: true
    allow_dirlist: true
    addons: false
    backup: false
    config: false
    media: true
    share: true
    ssl: false
log_level: debug
```

# Fritzbox smart home
* add the integration "AVM FRITZ!SmartHome"
* use the user and password combination of the Fritzbox istelf to authenticate

# Fritzbox Tools
* no entries anymore in yaml files, all setup with the integrations UI
* enabled entities `switch.<ipad-xyz>` to monitor kids WIFI 

# Fritzbox call monitor
* see https://www.home-assistant.io/integrations/fritzbox_callmonitor/
* Host: 192.168.178.1
* Port 1012
* Username hacallmon (using user hacallmon on Fritzbox)
* Passwort of user XXX
* you may need to enable the call monitor after a restart of the Fritzbox using "To activate the call monitor on your FRITZ!Box, dial #96*5* from any phone connected to it."
* hacallmon has rights to ...
  * FRITZ!Box Einstellungen
	* Sprachnachrichten, Faxnachrichten, FRITZ!App Fon und Anrufliste
	* Smart Home

# Influxdb
* installed with default settings
```
auth: true
reporting: true
ssl: true
certfile: fullchain.pem
keyfile: privkey.pem
envvars: []
```

# Grafana
* installed with configuration (note the plugin to visualize discrete values)
```
plugins:
  - natel-discrete-panel
env_vars: []
ssl: true
certfile: fullchain.pem
keyfile: privkey.pem
```

# Useful stuff

## Template

* Prints out all entities
```
{% for state in states %}
{{ state.entity_id }}
{%- endfor -%}
```
or
```
{% for state in states %}
{{ state.entity_id }}, {{ states(state.entity_id) }}
{%- endfor -%}
```

* export all entities to Excel (see https://community.home-assistant.io/t/export-entity-names/206262/17)
  * Open the file \config.storage\core.entity_registry 
  * Copy all the text and pasted in this random json to table converter (https://www.convertjson.com/json-to-html-table.htm)
  * works with devices, too

## Push automation to github
* an automation to regularly update my config to github (see https://github.com/swa72/home-assistant/blob/main/automations.yaml), credit: https://peyanski.com/automatic-home-assistant-backup-to-github/
* note that `hassio.addon_stdin` no longer works for this use case

```
- id: l1k3
  alias: push HA configuration to GitHub repo
  trigger:
    - at: '23:23'
      platform: time
  action:
    - service: shell_command.push_to_github
  mode: single
```
And there is an entry in my `configuration.yaml` file with 
```
shell_command:
  push_to_github: /config/gitpush.sh
```

* note to myself: check your `.gitignore` files if something doesn't get pushed. Images need to be added manually with `git add -f foo.jpg`


## notepad++ tips
* Editing files with Notepad++
  * Change tab with to 2 using ```Settings > Preferences > Language > Tab Settings```
* find and replace across files: Select Search > Find in Files from the menu. If you like keyboard shortcuts better, use Ctrl-Shift-F to open the search window instead.
* filter lines: mark lines (with Search | Mark), click on "bookmark line", remove other lines with Search | Bookmark | Remove Bookmarkes lines
  * or use https://stackoverflow.com/questions/21641810/remove-all-lines-except-lines-with-a-specific-word-notepad/52845652

## Garage
* Garage has one Shelly 1
  * http://s2/
  * Name in Shelly: shelly1_garage
  * Timer: Auto-off after 1s
  * Detached Switch - Set Shelly device to be in "Detached" switch mode - switch is separated from the relays.
* in HA
  * Device shelly1_garage
  * Entities
    * switch.shelly1_garage (opens or closes the garage)
    * binary_sensor.shelly1_garage_input (had to enable the entity manually; indicates whether garage is open or closed)
		* cover.garage_door, see `covers.yaml`

## Naming conventions for shelly devices
* The shelly device itself has a name (set in the UI of the shelly)
  * `<device-type>_<location>`
  * The same name is given to the device for the static ip adress in the fritzbox
    * `<device-type>-<location>`
* Naming conventions for the channels
  * `<device-type>_<location>_switch` (for the shelly1 and plugs)
  * `<device-type>_<location>_<function>` (for the shelly25)
  * note: haven't done this consistently :-/
* How to add a new shelly?
  * wire the shelly
  * connect to shelly's hotspot
  * for roller-shutter, select roller shutter
  * calibrate
  * connect to local WIFI
  * set DNS in fritzbox
  * update firmware of shelly using http://archive.shelly-tools.de
  * add device name
* I had a mess of devices and entities ...
  * delete all shelly integrations one by one .. (after having completed the renaming orgy)
  * restarted HA
  * HA discovers new shelly devices and shows them with "shellyswitch25-XXX". As soon as you click on "Configure" it replaces the device name with the one set in the shelly directly. Pick the right area and you're done.
  * watch out: if you have changed the channel names for a shelly25, the entities are named after the channel names!

## Too many homekit bridges
* I noticed two homekit bridges in my HA and, upon any restart, HA discovered yet another one.
* Removed all bridges from HA
* Deleted all bridges on the iPad
* Restartet HA
* Paired the bridge
* All configuring now thru yaml
* Re-doing the stuff is actually pretty quick

## Using MQTT explorer
* install it on a Windows machhine
* connect to the broker with 
  * username swamq
  * passwort <see keepass>
  * host homeassistant-eth
  * port 1883

# Deprecated stuff

## HACS: iCloud3 Device Tracker (deprecated, no longer in use)

* iCloud has authentication problems, so I was looking for an alternative
* see https://gcobb321.github.io/icloud3/#/
* config see https://github.com/swa72/home-assistant/blob/main/config_ic3.yaml

## Glances (deprecated, no longer in use)

* to monitor the Raspberry

```
log_level: info
process_info: false
refresh_time: 10
ssl: false
certfile: fullchain.pem
keyfile: privkey.pem
influxdb:
  enabled: false
  host: ##replaceme##
  port: 8086
  username: glances
  password: '!secret glances_influxdb_password'
  database: glances
  prefix: localhost
  interval: 60
```

## Backup to Samba Drive (deprecated, no longer in use)

* to have regular config backups to the USB stick of the Fritzbox
* note that username ##replaceme## must be available on the Fritzbox ("System > FRITZ!Box-Benutzer > Benutzer") and that particular user requires access to the attached USB stick

```
host: 192.168.178.1
share: FRITZ.NAS
target_dir: CCCOMA_X64F\ha
username: ##replaceme##
password: ##replaceme##
keep_local: 14
keep_remote: all
trigger_time: '00:00'
trigger_days:
  - Mon
  - Tue
  - Wed
  - Thu
  - Fri
  - Sat
  - Sun
exclude_addons: []
exclude_folders: []
backup_name: '{type} Snapshot {version} {date}'
```