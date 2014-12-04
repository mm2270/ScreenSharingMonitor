Screen Share Monitor 1.0
====================

A process for end user notifications of when a screen sharing session starts and ends

The toolset outlined below can be used in both a Casper Suite environment (Casper Remote) or with regular Apple Screen Sharing, and will distinguish properly between the two types.

####Components used in the process:  
1. A LaunchDaemon:  
      `com.mm2270.screensharemon.plist`  

2. A LaunchAgent:  
      `com.mm2270.screensharenotifier.plist`  

2. 2 local shell scripts:  
      `screenshare-monitor.sh`  
      `screenshare-notifier.sh`  

3. terminal-notifier (for the user notifications. This can be replaced with some other notification process, like an Applescript dialog, cocoaDialog, etc, if desired) You can also use a branded version of terminal-notifier, although the script is designed to make the notifications come from either Screen Sharing or Self Service (in the case of a Casper Remote Screen Sharing session)  

<br>
####Workflow
Once the LaunchAgent, LaunchDaemon and other components like terminal-notifier are installed in the appropriate locations, and the Daemon and Agent are loaded, the process works as follows:

######For Session Start Notifications
1. The LaunchDaemon runs every 12 seconds and runs a root level command that monitors for active (established) incoming Screen Sharing connections on the default port of 5900
2. If an active session is seen, the script checks to see if there is a local file in the path of **/Library/Application Support/ScreenSharingMonitor/ON**. If the file is present, it means a previous notification has already been displayed to the end user. It will exit silently in this instance.
3. If an active session is seen and the **"ON"** file is ***not*** present, it gathers information such as the connecting account (HostName, IP address or user name) as well as the current time and some other items, then creates the **"ON"** file and stores this informaiton in it in tab separated fields.
4. The LaunchDaemon also writes the above information into a /private/var/log/screenshare-notifier.log file.
5. The action of logging the information to the log file triggers the User Level LaunchAgent to pull the information from the log and generate the text for a notification, then sends the Notification Center message using the custom build terminal-notifier located in **/Library/Application Support/screenshare-notifier.app**  

<br>
######For Session End Notifications
Similar to the process outlined above, the LaunchDaemon does the following actions:

1. The LaunchDaemon runs every 12 seconds and runs a root level command that monitors for active (established) incoming Screen Sharing connections on the default port of 5900
2. If no active sessions are found, it checks to see if there is a local file in the path of **/Library/Application Support/ScreenSharingMonitor/ON**. If the file is present, it means a previous notification has already been displayed to the end user. But in this instance, it means it now needs to notify the user that the Screen Sharing session has ended.
3. If the **"ON"** file is present, it gathers information from the file, generates an appropriate message and writes a log entry for the end of the Screen Sharing session to **/private/var/log/screenshare-notifier.log**
4. The entry added to the **/private/var/log/screenshare-notifier.log** causes the user level LaunchAgent to activate and notify the user of the session end.
5. The LaunchDaemon waits a moment for the notification to complete, then deletes the **"ON"** file so no further notifications will appear.

NOTE: As part of the log entry, the LaunchDaemon calculates and writes in an approximate session length, based on the timestamp in the **"ON"** file and the time the session ended.  
  
<br>
######With no session active

If there is no active Screen Sharing session when the LaunchDaemon runs the script, it checks to see if a previous **/Library/Application Support/ScreenShareMonitor/ON** file is present. If there isn't one, it assumes no notifications need to be delivered and exits silently, waiting another 12 seconds to check again.  
  
<br>
####Compatibility

As the process as outlined above uses terminal-notifier, and thus Notification Center messages, in its default state it is compatible with OS X Mountain Lion 10.8.x and up through the current Yosemite 10.10.x.  
If you wish to have this work for older OS X versions before Notification Center was present, you would need to modify the ```screenshare-notifier.sh``` script to call a different messaging system, such as cocoaDialog, AppleScript or the like.  

Additionally, testing has been conducted on Casper Suite versions 8.73 and 9.61. It may work the same under even older Casper Suite releases, as well as new releases, but no testing beyond these versions has been conducted at this time.  
  
<br>
####Installation

If you wish to use the above components as is without modification, follow these steps:

1. Install ```com.mm2270.screensharemon.plist``` into ```/Library/LaunchDaemons/```
2. Install ```com.mm2270.screensharenotifier.plist``` into ```/Library/LaunchAgents/```
3. Create a new directory called **ScreenShareNotifier** inside ```/Library/Application\ Support/```
4. Install the following items into the ScreenShareNotifier directory:  
      • ```screenshare-monitor.sh```  
      • ```screenshare-notifier.sh```  
5. Download the custom built **screenshare-notifier.app** (built from terminal-notifier source code found [here](https://github.com/alloy/terminal-notifier)) and install it into ScreenShareNotifier directory.
6. Load both the LaunchDaemon and LaunchAgent using ```launchctl```, or reboot and log in to activate them.

####Additional Components
The custom built terminal-notifier (screenshare-notifier.app) can be found on the [Releases](https://github.com/mm2270/ScreenSharingMonitor/releases) page.

A prebuilt installer package that will install all requisite files and loads the LaunchAgent and LaunchDaemon after installation can be downloaded on the [Releases](https://github.com/mm2270/ScreenSharingMonitor/releases) page.


####Known Issues

The following lists some known issues with the process as designed.  

1. I have not been able to locate an exact tell tale sign that a Screen Sharing session has started. There don't seem to be any (reliable) files or folders that are created, modified or destroyed in the OS at the time of a session start or end. The best it seems we can do is continously monitor port 5900 for inbound established connections. Hence why the LaunchDaemon uses a StartInterval of 12 seconds rather than a WatchPath for example.
2. When a remote connection is started using the OSes built in Screen Sharing.app, at the time the authentication prompt appears for the remote connecting admin, port 5900 shows an "established" connection. As a result, a notification may appear about an active Screen Sharing connection even before the initiating user has successfully authenticated and connected to the remote Mac. There doesn't seem to be a good way to prevent this from happening as things stand right now. There is no difference in how the connection appears on the system before and after successful authentication.  
If I ever discover a more reliable way of knowing when **only** a valid authentication and connection is established, I will update the script accordingly.  
**NOTE:** This last issue doesn't affect Casper Remote Screen Sharing sessions if the "Screen Share with Remote Computers Without Asking" option is ***unchecked*** for the account. The Notification Center alert will only appear after the remote admin is granted permission to view the user's screen, by the user. If the connection is denied instead, no message appears.
