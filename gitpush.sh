#!/bin/bash
cd /config
git add .
git status
# Commit changes with message with current date stamp
git commit -m "config files on `date +'%d-%m-%Y %H:%M:%S'`"
# Push changes towards GitHub
git push -u origin master
exit
