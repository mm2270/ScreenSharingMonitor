Screen Share Monitor 1.0
====================

A process for end user notifications of when a screen sharing session starts and ends

### Components used in the process:  
1. A LaunchDaemon  
2. A LaunchAgent
2. 2 local shell scripts  
3. terminal-notifier (for the user notifications. This can be replaced with some other notification process, like an Applescript dialog, cocoaDialog, etc, if desired) You can also use a branded version of terminal-notifier, although the script is designed to make the notifications come from either Screen Sharing or Self Service (in the case of a Casper Remote Screen Sharing session)

##### Workflow
Once the LaunchAgent, LaunchDaemon and other components like terminal-notifier are installed in the appropriate locations, and the Daemon and Agent are loaded, the process works as follows:

######For Session Start Notifications
1. The LaunchDaemon runs every 12 seconds and runs a root level command that monitors for active (established) incoming Screen Sharing connections on the default port of 5900
2. If an active session is seen, the script checks to see if there is a local file in the path of **/Library/Application Support/ScreenSharingMonitor/ON**. If the file is present, it means a previous notification has already been displayed to the end user.
3. If the **"ON"** file is not present, it gathers information such as the connecting account (HostName or UserName) as well as the current time and some other items, then creates the **"ON"** file and stores the above informaiton in it in tab separated fields.
4. The LaunchDaemon also writes the above information into a /private/var/log/screenshare-notifier.log file.
5. The action of logging the information above triggers the User Level LaunchAgent to pull the informaiton from the log and generate the text for a notificaiton, then sends the Notification Center message using the custom build terminal-notifier located in **/Library/Application Support/screenshare-notifier.app**

######For Session End Notifications
Similar to the process outlined above, the LaunchDaemon does the following actions:

1. Runs every 12 seconds and runs a root level command that monitors for active (established) incoming Screen Sharing connections on the default port of 5900
2. If no active sessions are found, it checks to see if there is a local file in the path of **/Library/Application Support/ScreenSharingMonitor/ON**. If the file is present, it means a previous notification has already been displayed to the end user. But in this instance, it means it now needs to notify the user that the Screen Sharing session has ended.
3. If the **"ON"** file is present, it gathers information from the file, generates an appropriate message and writes a log entry for the end of the Screen Sharing session.
4. The entry in the **/private/var/log/screenshare-notifier.log** causes the LaunchAgent to active and notify the user of the session end.
5. The LaunchDaemon waits a moment for the notificaiton to complete, then deletes the **"ON"** file so no further notifications will appear.

NOTE: As part of the log entry, the LaunchDaemon calculates and writes in an approximate session length, based on the timestamp in the **"ON"** file and the time the session ended.
