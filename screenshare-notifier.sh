#!/bin/bash

## Script: 	screenshare-notifier.sh
## Author:	Mike Morales
## Last change:	2014-11-28

## The path to screenshare-notifier's executable (a repackaged version of terminal-notifier)
SSNapp="/Library/Application Support/ScreenShareNotifier/screenshare-notifier.app/Contents/MacOS/screenshare-notifier"

## The path to the screenshare-notifier's log file
sslog="/private/var/log/screenshare-notifier.log"
activator="/Library/Application Support/ScreenShareNotifier/ON"

## Set the notification start and end sounds
if [ -e "/System/Library/Sounds/Hero.aiff" ]; then
	startSnd="Hero"
else
	startSnd="default"
fi

if [ -e "/System/Library/Sounds/Glass.aiff" ]; then
	endSnd="Glass"
else
	endSnd="default"
fi


if [ -e "$sslog" ]; then
	fullMsg=$(tail -4 "$sslog")
	titleMsg=$(echo "$fullMsg" | grep "Screen Sharing -")
	bodyMsg=$(echo "$fullMsg" | grep "ScreenSharing session")
fi

if [[ "$titleMsg" =~ "ON" ]]; then
	Snd="${startSnd}"
elif [[ "$titleMsg" =~ "OFF" ]]; then
	Snd="${endSnd}"
fi

if [ -e "$activator" ]; then
	ID=$(awk -F'[\t]' '{print $2}' "$activator")
fi
	
if [[ ! -z "$fullMsg" ]] && [[ ! -z "$bodyMsg" ]] && [[ ! -z "$ID" ]]; then
	"$SSNapp" -title "${titleMsg}" -message "${bodyMsg}" -sender ${ID} -sound "${Snd}"
else
	echo "Error: Could not obtain valid information for messaging"
fi
