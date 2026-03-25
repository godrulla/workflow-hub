#!/usr/bin/env python3
"""
Simple Working Workflow Hub Launcher
Just starts backend, then GUI
"""

import subprocess
import os
import sys
import time
from pathlib import Path

# Change to the script directory
script_dir = Path(__file__).parent
os.chdir(script_dir)

print("🎯 WORKFLOW HUB - Starting System...")

# 1. Start backend in background
print("🚀 Starting backend server...")
backend_process = subprocess.Popen([
    "./venv/bin/python", 
    "Backend/gui_websocket_server.py"
], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# Give it time to start
time.sleep(3)

# 2. Start GUI in foreground
print("🖥️  Starting GUI application...")
os.chdir("WorkflowHubGUI")
subprocess.run(["swift", "run"])

# GUI closed, so clean up backend
backend_process.terminate()
print("🎯 System shutdown complete")