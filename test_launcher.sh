#!/bin/bash

# Simple test launcher to verify the app bundle works
osascript -e 'tell app "System Events" to display dialog "🎯 TEST: Workflow Hub App Bundle is Working! 🎯

This confirms that:
✅ You clicked the app successfully
✅ The launcher script is executing
✅ AppleScript dialogs work

Next I will run a simple command to show Terminal output..." buttons {"Continue"} default button "Continue" with icon note with title "Workflow Hub Test"'

# Open Terminal and run a simple test
osascript -e 'tell app "Terminal" 
    activate
    do script "echo \"🎯 WORKFLOW HUB TEST - Terminal Window Opened Successfully!\" && echo \"If you see this, the app bundle is working.\" && echo \"Press any key to continue...\" && read"
end tell'