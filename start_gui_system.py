#!/usr/bin/env python3
"""
Workflow Hub GUI System Launcher
Complete system startup script for macOS GUI + Backend
Author: Armando Diaz Silverio
"""

import os
import sys
import subprocess
import time
import threading
from pathlib import Path
import signal

def print_banner():
    banner = """
╔══════════════════════════════════════════════════════════════════════════════════╗
║                                                                                  ║
║    🎯 WORKFLOW HUB GUI SYSTEM LAUNCHER 🎯                                      ║
║                                                                                  ║
║    Executive-Level macOS Application + Real-time Backend                        ║
║    Built for Maximum Productivity and Universe Conquest                         ║
║                                                                                  ║
╚══════════════════════════════════════════════════════════════════════════════════╝
    """
    print(banner)

class WorkflowHubGUILauncher:
    def __init__(self):
        self.base_path = Path(__file__).parent
        self.backend_process = None
        self.gui_process = None
        self.running = True
        
    def start_backend_server(self):
        """Start the WebSocket backend server"""
        print("🚀 Starting WebSocket Backend Server...")
        
        backend_script = self.base_path / "Backend" / "gui_websocket_server.py"
        
        try:
            self.backend_process = subprocess.Popen(
                [sys.executable, str(backend_script)],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True
            )
            
            # Give server time to start
            time.sleep(2)
            
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
    
    def start_gui_application(self):
        """Start the macOS GUI application"""
        print("🖥️  Starting macOS GUI Application...")
        
        gui_path = self.base_path / "WorkflowHubGUI"
        
        try:
            # Check if we can build the Swift app
            build_result = subprocess.run(
                ["swift", "build"],
                cwd=gui_path,
                capture_output=True,
                text=True
            )
            
            if build_result.returncode == 0:
                print("✅ Swift application built successfully")
                
                # Run the application
                self.gui_process = subprocess.Popen(
                    ["swift", "run"],
                    cwd=gui_path,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE
                )
                
                print("✅ macOS GUI Application launched")
                return True
            else:
                print("❌ Failed to build Swift application:")
                print(build_result.stderr)
                return False
                
        except FileNotFoundError:
            print("❌ Swift not found. Please install Xcode Command Line Tools:")
            print("   xcode-select --install")
            return False
        except Exception as e:
            print(f"❌ Error starting GUI application: {e}")
            return False
    
    def monitor_backend_logs(self):
        """Monitor and display backend logs"""
        if not self.backend_process:
            return
            
        def log_reader():
            while self.running and self.backend_process and self.backend_process.poll() is None:
                try:
                    line = self.backend_process.stdout.readline()
                    if line:
                        print(f"🔧 Backend: {line.strip()}")
                except:
                    break
                    
        log_thread = threading.Thread(target=log_reader, daemon=True)
        log_thread.start()
    
    def check_dependencies(self):
        """Check if required dependencies are available"""
        print("🔍 Checking system dependencies...")
        
        # Check Python dependencies
        try:
            import websockets
            import asyncio
            print("✅ Python WebSocket dependencies available")
        except ImportError:
            print("❌ Missing Python dependencies.")
            print("💡 Please run the setup script first:")
            print("   python3 setup_venv.py")
            print("   Then use: python3 start_gui_with_venv.py")
            return False
        
        # Check Swift/Xcode
        try:
            result = subprocess.run(["swift", "--version"], capture_output=True, text=True)
            if result.returncode == 0:
                print("✅ Swift compiler available")
            else:
                print("❌ Swift compiler not available")
                return False
        except FileNotFoundError:
            print("❌ Swift not found. Please install Xcode Command Line Tools")
            return False
            
        # Check if workflow-hub system is available
        if (self.base_path / "orchestration" / "agent_mcp_bridge.py").exists():
            print("✅ Workflow Hub system integration available")
        else:
            print("⚠️  Running in standalone mode (workflow-hub integration not found)")
            
        return True
    
    def setup_signal_handlers(self):
        """Setup signal handlers for graceful shutdown"""
        def signal_handler(signum, frame):
            print(f"\n🛑 Received signal {signum}, shutting down gracefully...")
            self.shutdown()
            
        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)
    
    def shutdown(self):
        """Gracefully shutdown all processes"""
        print("\n🔄 Shutting down Workflow Hub GUI System...")
        
        self.running = False
        
        if self.gui_process:
            print("   Stopping GUI Application...")
            self.gui_process.terminate()
            try:
                self.gui_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.gui_process.kill()
            print("   ✅ GUI Application stopped")
        
        if self.backend_process:
            print("   Stopping Backend Server...")
            self.backend_process.terminate()
            try:
                self.backend_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.backend_process.kill()
            print("   ✅ Backend Server stopped")
            
        print("🎯 Workflow Hub GUI System shut down complete")
        sys.exit(0)
    
    def show_usage_instructions(self):
        """Show instructions for using the system"""
        instructions = """
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            🎯 SYSTEM READY!                                    │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  Your executive-level Workflow Hub GUI is now running!                         │
│                                                                                 │
│  📊 Dashboard: Overview of all agents and projects                             │
│  🤖 Elite Agents: Monitor and manage your 7 specialized agents                │
│  📁 Projects: Track all 23+ business projects in real-time                    │
│  🔀 Workflows: Execute and monitor business/product workflows                  │
│  📈 Analytics: Token usage, performance metrics, insights                      │
│  💻 Commander: Direct command interface for power users                        │
│                                                                                 │
│  🔗 WebSocket Server: ws://localhost:8765                                     │
│  🖥️  GUI Application: Running with real-time updates                          │
│                                                                                 │
│  ⚡ Features Available:                                                        │
│     • Real-time agent status monitoring                                        │
│     • Token usage analytics and optimization                                   │
│     • Project health and progress tracking                                     │
│     • Intelligent task delegation                                              │
│     • Workflow execution and monitoring                                        │
│     • Executive-level productivity insights                                    │
│                                                                                 │
│  🎮 Controls:                                                                  │
│     • Click agents to view detailed performance                                │
│     • Drag tasks between agents for delegation                                 │
│     • Monitor token usage and system health                                    │
│     • Execute workflows with visual progress tracking                          │
│                                                                                 │
│  📝 Next Steps:                                                               │
│     1. Explore the Dashboard for system overview                               │
│     2. Check Elite Agents for current status                                   │
│     3. Review Projects for business priorities                                 │
│     4. Use Commander for direct system control                                 │
│                                                                                 │
│  Press Ctrl+C to shutdown the system gracefully                               │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
        """
        print(instructions)
    
    def run(self):
        """Main execution method"""
        print_banner()
        
        # Setup signal handlers
        self.setup_signal_handlers()
        
        # Check dependencies
        if not self.check_dependencies():
            print("❌ Dependency check failed. Please resolve issues and try again.")
            return 1
        
        # Start backend server
        if not self.start_backend_server():
            print("❌ Failed to start backend server")
            return 1
        
        # Monitor backend logs
        self.monitor_backend_logs()
        
        # Start GUI application
        if not self.start_gui_application():
            print("❌ Failed to start GUI application")
            self.shutdown()
            return 1
        
        # Show usage instructions
        self.show_usage_instructions()
        
        # Keep the launcher running
        try:
            while self.running:
                time.sleep(1)
                
                # Check if processes are still running
                if self.backend_process and self.backend_process.poll() is not None:
                    print("❌ Backend server stopped unexpectedly")
                    self.shutdown()
                    return 1
                    
                if self.gui_process and self.gui_process.poll() is not None:
                    print("ℹ️  GUI application closed")
                    self.shutdown()
                    return 0
                    
        except KeyboardInterrupt:
            self.shutdown()
            return 0
        
        return 0

def main():
    launcher = WorkflowHubGUILauncher()
    return launcher.run()

if __name__ == "__main__":
    sys.exit(main())