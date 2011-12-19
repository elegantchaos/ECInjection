#!/bin/sh

# tell the system to unload the injector
sudo launchctl unload /Library/LaunchDaemons/com.elegantchaos.injection.injector.plist

# remove injector
sudo rm -f /Library/PrivilegedHelperTools/com.elegantchaos.injection.injector 

# remove launchctl plist
sudo rm -f /Library/LaunchDaemons/com.elegantchaos.injection.injector.plist
