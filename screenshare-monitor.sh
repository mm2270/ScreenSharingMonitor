#!/bin/sh

## Script: 	screenshare-monitor.sh
## Author:	Mike Morales
## Last change:	2014-11-21

## The path to the screenshare-notifier's log file
sslog="/private/var/log/screenshare-notifier.log"

## Create the screenshare-notifier log if it doesn't exist
if [ ! -e "$sslog" ]; then
	touch "$sslog"
fi

## The logging function
function log ()
{

echo "$1" >> "$sslog"

}


f_notifyStart ()
{

## Function runs when a screen sharing session IS active. It does the following:
##		Looks for a previous '/Library/Application Support/ScreenShareNotifier/ON' file
## 		If one is NOT found, echoes the following values into a new '/Library/Application Support/ScreenShareNotifier/ON' file separated by tabs:
##			1) Requesting user info (username or computer name)
##			2) The Bundle ID (for the icon)
##			3) The session type (Casper Remote or standard Screen Sharing)
## 		Builds a message string from the above values
## 		Logs the string to the local log file at '/private/var/log/screenshare-notifier.log'
##		Looks for a logged in user (we can't display a Notification if at the login screen)
## 		Delivers the 'session start' notification to the logged in user
##		Or, exits silently if a previous '/Library/Application Support/ScreenShareNotifier/ON' is found (prevents repeated notifications during a session)

## Check to see if the 'ON' file is present
if [[ ! -e "/Library/Application Support/ScreenShareNotifier/ON" ]]; then

	## Get the current date and format it
	theDate=$(date +"%m/%d/%Y %l:%M %p")
	theDateSecs=$(date +"%s")
	## Set up a message string we will display in screenshare-notifier as well as send to the log file
	msg="${theDate}: A ${SSType} session started to your Mac from: ${reqUser}"
		
	## Log the session start to the log file
	log "Screen Sharing - ON\n$msg\n"
		
	## Create the 'ON' file with the above values for later extraction
	echo "${reqUser}\t${ID}\t${SSType}\t${theDateSecs}" > "/Library/Application Support/ScreenShareNotifier/ON"

else
	
	## A message was already displayed. Exit for now
	exit 0
	
fi

}

f_notifyEnd ()
{

## Function runs when a screen sharing session is NOT active. It does the following:
##		Looks for a previous '/Library/Application Support/ScreenShareNotifier/ON' file 
## 		If one is found, extracts the following from the file:
##			1) Requesting user info (username, hostname or IP)
##			2) The Bundle ID (for the icon)
##			3) The session type (Casper Remote or standard Screen Sharing)
## 		Builds a message string from the above values
## 		Logs the string to the local log file at '/private/var/log/screenshare-notifier.log'
## 		Removes the '/private/screensharing/ON' file
## 		Or, exits silently if there is no previous 'ON' file found

if [[ -e "/Library/Application Support/ScreenShareNotifier/ON" ]]; then
			
	## Extract information from the 'ON' file
	reqUser=$(awk -F'[\t]' '{print $1}' "/Library/Application Support/ScreenShareNotifier/ON")
	ID=$(awk -F'[\t]' '{print $2}' "/Library/Application Support/ScreenShareNotifier/ON")
	SSType=$(awk -F'[\t]' '{print $3}' "/Library/Application Support/ScreenShareNotifier/ON")
	startTime=$(awk -F'[\t]' '{print $4}' "/Library/Application Support/ScreenShareNotifier/ON")
		
	## Calculate session length (for reporting in the log)
	totalTime=$(expr $(date +"%s") - ${startTime})
	hours=$((totalTime/60/60%24))
	mins=$((totalTime/60%60))
	secs=$((totalTime%60))
	sessionTime=$(printf '%02d:' $hours; printf '%02d:' $mins; printf '%02d\n' $secs)
		
	## Get the current date
	theDate=$(date +"%m/%d/%Y %l:%M %p")
		
	## Set up a message string for the notification
	msg="$theDate: A ${SSType} session stopped to your Mac from: ${reqUser}"
		
	## Log the session end to the log file
	log "Screen Sharing - OFF\n$msg\nSession length: ${sessionTime}$(echo "\n$(printf '%.0s=' {1..24}; echo)\n")"

	sleep 2
	
	## Delete the 'ON' file to prevent any other messages being displayed
	rm -f "/Library/Application Support/ScreenShareNotifier/ON"

else
	
	## No previous session file found. Exit until next run
	exit 0
	
fi

}

## Beginning of the script

## Check for 'established' screen sharing sessions on port 5900
SSline=$(lsof -i :5900 | awk '/:rfb/ && /(ESTABLISHED)/{print}' | grep -v ":rfb (ESTABLISHED)" | grep -v "sshd")
if [[ "$SSline" != "" ]]; then

	## If a local "casperscreensharing" account is found on the system,
	## the screen sharing session is probably initiated by Casper Remote	
	if [[ $(dscl . list /Users | grep "casperscreensharing") ]]; then
	
		## Set up appropriate variables
		reqUser=$(awk '/Permission granted by user for/{print $NF}' /private/var/log/jamf.log | tail -1)
		if [ -z "$reqUser" ]; then
			reqUser=$(echo "$SSline" | awk -F"[>|:]" '{print $3}')
		fi
		ID="com.jamfsoftware.selfservice"
		SSType="Casper ScreenSharing"
		CRSession="yes"
		
	else
	
	## Otherwise, its a standard screen sharing session
		## Set up appropriate variables
		reqUser=$(echo "$SSline" | awk -F"[>|:]" '{print $3}')
		ID="com.apple.ScreenSharing"
		SSType="ScreenSharing"
		CRSession="no"
		
	fi
	
	## Run the session notify start function
	f_notifyStart
	
else

	## Run the session notify end function
	f_notifyEnd
fi
