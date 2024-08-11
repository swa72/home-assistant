#!/bin/bash
date >> /config/git-last.txt
cd /config
# evcc.yaml now resides on remote server
scp  192.168.178.143:/etc/evcc.yaml .
# sanitize
egrep -v '^#|^\s+#' evcc.yaml |grep . |sed -E 's/(password|user|token|url|host|broker|accessToken|refreshToken|vin|title).*/\1: *****/' > evcc-sanitized.yaml
git add .
git status
# Commit changes with message with current date stamp
git commit -m "config files on `date +'%d-%m-%Y %H:%M:%S'`"
# Push changes towards GitHub
git push -u origin main
exit
