#!/usr/bin/env python3
"""
Working Workflow Hub Launcher
Launches the functional backend + GUI system
"""

import subprocess
import sys
import os
import time
import signal
import threading
from pathlib import Path

def show_banner():
    print("""
╔══════════════════════════════════════════════════════════════════════════════════╗
║                                                                                  ║
║    🎯 WORKFLOW HUB - FUNCTIONAL VERSION 🎯                                     ║
║                                                                                  ║
║    Elite Agents + Real-time Backend + Native macOS GUI                          ║
║    Now with FULL FUNCTIONALITY!                                                 ║
║                                                                                  ║
╚══════════════════════════════════════════════════════════════════════════════════╝
    """)

class WorkingWorkflowHub:
    def __init__(self):
        self.base_path = Path(__file__).parent
        self.backend_process = None
        self.gui_process = None
        self.running = True
        
    def start_backend(self):
        """Start the WebSocket backend"""
        print("🚀 Starting WebSocket Backend Server...")
        
        venv_python = self.base_path / "venv" / "bin" / "python"
        backend_script = self.base_path / "Backend" / "gui_websocket_server.py"
        
        try:
            self.backend_process = subprocess.Popen(
                [str(venv_python), str(backend_script)],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True,
                cwd=str(self.base_path)
            )
            
            # Give server time to start
            time.sleep(3)
            
            if self.backend_process.poll() is None:
                print("✅ WebSocket Backend Server started successfully")
                return True
            else:
                stdout, stderr = self.backend_process.communicate()
                print(f"❌ Backend server failed to start:")
                print(f"STDOUT: {stdout}")
                print(f"STDERR: {stderr}")
                return False
                
        except Exception as e:
            print(f"❌ Error starting backend server: {e}")
            return False
    
    def start_gui(self):
        """Start the Swift GUI"""
        print("🖥️  Starting macOS GUI Application...")
        
        gui_path = self.base_path / "WorkflowHubGUI"
        
        try:
            # Use swift run directly since we know it works
            self.gui_process = subprocess.Popen(
                ["swift", "run"],
                cwd=str(gui_path),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True
            )
            
            print("✅ macOS GUI Application launched successfully")
            print("")
            print("🎮 GUI Features Available:")
            print("   • Live Elite Agent monitoring (ARQ, ORC, ZEN, VEX, SAGE, NOVA, ECHO)")
            print("   • Real-time system metrics and token usage")
            print("   • Project management dashboard") 
            print("   • WebSocket connectivity with live updates")
            print("   • Professional macOS native interface")
            print("")
            print("📡 WebSocket Server: ws://localhost:8765")
            print("🔄 Updates every 2 seconds")
            print("")
            print("Press Ctrl+C to stop the system")
            return True
            
        except Exception as e:
            print(f"❌ Error starting GUI application: {e}")
            return False
    
    def monitor_processes(self):
        """Monitor both processes"""
        def log_backend():
            if self.backend_process:
                for line in iter(self.backend_process.stderr.readline, ''):
                    if line.strip():
                        print(f"🔧 Backend: {line.strip()}")
        
        # Start background logging
        if self.backend_process:
            backend_thread = threading.Thread(target=log_backend, daemon=True)
            backend_thread.start()
        
        try:
            while self.running:
                time.sleep(1)
                
                # Check if processes are still running
                if self.backend_process and self.backend_process.poll() is not None:
                    print("❌ Backend server stopped unexpectedly")
                    self.shutdown()
                    return False
                    
                if self.gui_process and self.gui_process.poll() is not None:
                    print("ℹ️  GUI application closed")
                    self.shutdown()
                    return True
                    
        except KeyboardInterrupt:
            print("\n🛑 Shutting down...")
            self.shutdown()
            return True
    
    def shutdown(self):
        """Clean shutdown"""
        self.running = False
        
        if self.gui_process:
            print("   Stopping GUI...")
            self.gui_process.terminate()
            try:
                self.gui_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.gui_process.kill()
        
        if self.backend_process:
            print("   Stopping Backend...")
            self.backend_process.terminate()
            try:
                self.backend_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.backend_process.kill()
        
        print("🎯 Workflow Hub shutdown complete")
    
    def run(self):
        """Main execution"""
        show_banner()
        
        # Start backend
        if not self.start_backend():
            print("❌ Failed to start backend. Exiting.")
            return 1
        
        # Start GUI
        if not self.start_gui():
            print("❌ Failed to start GUI. Exiting.")
            self.shutdown()
            return 1
        
        # Monitor both
        result = self.monitor_processes()
        return 0 if result else 1

if __name__ == "__main__":
    launcher = WorkingWorkflowHub()
    sys.exit(launcher.run())