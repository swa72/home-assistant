# home-assistant

My first attempt at running a home automation system was a Shelly device integrated to HomeKit - worked nicely. Then I fiddled around with running https://homebridge.io/ on my Raspberry 4, moved over to https://hoobs.org/ and realized that there must be something better. Luckily I found Home Assistant.

## My goal

Have a nice and easy interface for the house on the iPad (no need for my wife and kids to access any of the Home Assistant stuff). Have an advanced interface to the house for myself.

This file is intended for me to document the quirks I had during setup and for others to learn and avoid them.

## My setup

* Router Fritz!Box 7490 with open external ports 443 and 8123 to the raspi 4 (no DynDNS on fritz.box)
  * my doorbell is directly hooked up to the fritzbox
  * fritzbox has an attached USB stick
* Raspberry 4 running Home Assistant OS 5.9
  * initially connected thru wifi, later moved to ethernet and directly connected to the fritzbox
  * conbee USB stick to manage ZigBee network
* I run the following add-ons
	* DuckDNS
	* motionEye
	  * an old iPhone serving as a guinea pig camera
	  * for motionEye's webhooks I had to install NGINX as add-on (see https://community.home-assistant.io/t/motioneye-integration/194350/42)
	  * if motion is detected 
	* AdGuard Home 
	  * filters out ads and other stuff (serves as DNS-server for the fritzbox)
	* File editor 
	* Glances to monitor the raspi
	* Log Viewer
	* SSH & Web Terminal
	  * not to be confused with "Terminal & SSH"
	  * this is as special version which gives me elevated access to the raspi
	* Samba Backup to have regular config backups to the USB stick of the fritzbox
	* Samba share to be able to access and edit files on the raspi
	* deCONZ
	