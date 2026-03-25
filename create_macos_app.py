#!/usr/bin/env python3
"""
Create macOS Application Bundle for Workflow Hub GUI
This creates a proper .app bundle that can be double-clicked from Finder
"""

import os
import sys
import shutil
from pathlib import Path
import plistlib

def create_app_bundle():
    """Create a proper macOS .app bundle"""
    
    project_dir = Path(__file__).parent
    app_name = "Workflow Hub"
    app_bundle = project_dir / f"{app_name}.app"
    
    print(f"🚀 Creating macOS app bundle: {app_bundle}")
    
    # Remove existing app bundle
    if app_bundle.exists():
        shutil.rmtree(app_bundle)
    
    # Create app bundle structure
    contents_dir = app_bundle / "Contents"
    macos_dir = contents_dir / "MacOS"
    resources_dir = contents_dir / "Resources"
    
    contents_dir.mkdir(parents=True)
    macos_dir.mkdir(parents=True)
    resources_dir.mkdir(parents=True)
    
    # Create Info.plist
    info_plist = {
        'CFBundleName': app_name,
        'CFBundleDisplayName': 'Workflow Hub - Productivity Command Center',
        'CFBundleIdentifier': 'com.exxede.workflowhub',
        'CFBundleVersion': '1.0.0',
        'CFBundleShortVersionString': '1.0.0',
        'CFBundleExecutable': 'workflow_hub_launcher',
        'CFBundleIconFile': 'AppIcon.icns',
        'CFBundlePackageType': 'APPL',
        'CFBundleSignature': '????',
        'LSMinimumSystemVersion': '13.0',
        'NSHighResolutionCapable': True,
        'NSRequiresAquaSystemAppearance': False,
        'LSUIElement': False,
        'NSSupportsAutomaticGraphicsSwitching': True,
        'CFBundleDocumentTypes': [],
        'UTExportedTypeDeclarations': [],
        'NSHumanReadableCopyright': '© 2025 Exxede Investments.'
    }
    
    with open(contents_dir / "Info.plist", "wb") as f:
        plistlib.dump(info_plist, f)
    
    print("✅ Created Info.plist")
    
    # Create launcher script
    launcher_script = macos_dir / "workflow_hub_launcher"
    launcher_content = f'''#!/bin/bash

# Workflow Hub macOS App Launcher
# This script runs the Workflow Hub GUI system

# Get the directory of this app bundle
APP_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")/../../../" && pwd)"

# Change to the project directory
cd "$APP_DIR"

# Check if virtual environment exists
if [ ! -d "$APP_DIR/venv" ]; then
    # Show setup dialog using AppleScript
    osascript -e 'tell app "System Events" to display dialog "Workflow Hub needs to install dependencies. Click OK to proceed with automatic setup." buttons {{"Cancel", "OK"}} default button "OK" with icon caution'
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    # Run setup in a new Terminal window
    osascript -e 'tell app "Terminal" to do script "cd \\"'$APP_DIR'\\" && python3 setup_venv.py && echo \\"Setup complete. You can now close this window and double-click the Workflow Hub app again.\\" && read -p \\"Press Enter to close...\\""'
    exit 0
fi

# Check if Swift is available
if ! command -v swift &> /dev/null; then
    osascript -e 'tell app "System Events" to display dialog "Swift/Xcode is required but not found. Please install Xcode Command Line Tools by running: xcode-select --install" buttons {{"OK"}} default button "OK" with icon stop'
    exit 1
fi

# Launch the GUI system using the virtual environment
"$APP_DIR/venv/bin/python" "$APP_DIR/start_gui_system.py" 2>&1 | while IFS= read -r line; do
    echo "$(date): $line"
done

# If we get here, the app has closed
echo "Workflow Hub GUI closed"
'''
    
    launcher_script.write_text(launcher_content)
    launcher_script.chmod(0o755)
    
    print("✅ Created launcher script")
    
    # Create app icon (using system icon for now)
    create_app_icon(resources_dir)
    
    # Copy project files to Resources (optional, for self-contained app)
    # For now, we'll reference the original location
    
    print(f"✅ macOS app bundle created: {app_bundle}")
    
    # Make the entire app bundle executable
    os.chmod(app_bundle, 0o755)
    
    return app_bundle

def create_app_icon(resources_dir):
    """Create app icon from system icons"""
    
    # Create a simple icon using system utilities
    icon_script = '''
    import Cocoa
    import Quartz
    
    # Create icon programmatically
    let size = NSSize(width: 1024, height: 1024)
    let image = NSImage(size: size)
    
    image.lockFocus()
    
    // Draw background gradient
    let gradient = NSGradient(colors: [
        NSColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0),
        NSColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
    ])
    gradient?.draw(in: NSRect(origin: .zero, size: size), angle: -90)
    
    // Draw gear icon
    let gearPath = NSBezierPath()
    // ... (simplified - would draw gear shape)
    NSColor.white.setFill()
    gearPath.fill()
    
    image.unlockFocus()
    
    // Save as ICNS
    if let tiffData = image.tiffRepresentation,
       let bitmapRep = NSBitmapImageRep(data: tiffData) {
        let iconData = bitmapRep.representation(using: .png, properties: [:])
        // Convert to ICNS format
    }
    '''
    
    # For now, create a simple text-based icon placeholder
    icon_path = resources_dir / "AppIcon.icns"
    
    # Try to use system iconutil if available
    try:
        # Create iconset directory structure
        iconset_dir = resources_dir / "AppIcon.iconset"
        iconset_dir.mkdir(exist_ok=True)
        
        # Create different icon sizes (we'll use a simple approach)
        # In a real implementation, you'd create proper PNG files at different sizes
        
        # Use sips to create a simple icon from system resources
        import subprocess
        
        # Try to copy a system icon as a starting point
        system_icon = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ExecutableBinaryIcon.icns"
        if Path(system_icon).exists():
            shutil.copy2(system_icon, icon_path)
            print("✅ Created app icon from system resources")
        else:
            # Create a placeholder
            icon_path.touch()
            print("⚠️  Created placeholder icon (consider adding custom icon)")
            
    except Exception as e:
        print(f"⚠️  Could not create icon: {e}")
        icon_path.touch()

def create_desktop_alias():
    """Create a desktop alias/shortcut"""
    try:
        desktop_path = Path.home() / "Desktop"
        project_dir = Path(__file__).parent
        app_bundle = project_dir / "Workflow Hub.app"
        
        if app_bundle.exists():
            # Create symbolic link on desktop
            desktop_link = desktop_path / "Workflow Hub.app"
            if desktop_link.exists():
                desktop_link.unlink()
            
            desktop_link.symlink_to(app_bundle)
            print(f"✅ Created desktop shortcut: {desktop_link}")
            return True
    except Exception as e:
        print(f"⚠️  Could not create desktop shortcut: {e}")
    
    return False

def main():
    print("""
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║    🍎 MACOS APP BUNDLE CREATOR 🍎                          ║
║                                                              ║
║    Creating double-click launcher for Workflow Hub          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
    """)
    
    try:
        app_bundle = create_app_bundle()
        
        # Ask if user wants desktop shortcut
        print(f"""
🎉 macOS App Bundle Created Successfully!

App Location: {app_bundle}

You can now:
1. Double-click the app bundle to launch Workflow Hub
2. Drag it to your Applications folder
3. Add it to your Dock
        """)
        
        # Try to create desktop shortcut
        if create_desktop_alias():
            print("📱 Desktop shortcut created - you can now double-click 'Workflow Hub' on your desktop!")
        
        print("""
🚀 Next Steps:
1. Double-click 'Workflow Hub.app' to launch (it will setup dependencies first time)
2. The app will guide you through any remaining setup
3. Once running, you'll have your executive productivity command center!

⚡ Features Available:
• Real-time Elite Agent monitoring  
• Token usage analytics
• Project command center
• Workflow execution interface
• Executive productivity metrics

Ready to conquer the universe! 🌟
        """)
        
        return 0
        
    except Exception as e:
        print(f"❌ Error creating app bundle: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())