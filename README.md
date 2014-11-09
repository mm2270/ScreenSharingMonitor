ScreenSharingMonitor
====================

A process for end user notifications of when a screen sharing session starts and ends

### Components used in the process:  
1. A LaunchDaemon  
2. A local shell script  
3. terminal-notifier (for the user notifications. This can be replaced with some other notification process, like an Applescript dialog, cocoaDialog, etc, if desired) You can also use a branded version of terminal-notifier.  

##### Workflow
