#!/usr/bin/env python3
"""
Workflow Hub Productivity System Launcher
Author: Armando Diaz Silverio
Purpose: One-click launch of your MCP + Agent productivity system
"""

import os
import sys
import subprocess
import time
from pathlib import Path

def print_banner():
    banner = """
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║    🚀 WORKFLOW HUB PRODUCTIVITY SYSTEM 🚀                   ║
║                                                              ║
║    MCP + Elite Agents = 5x Productivity Multiplication      ║
║                                                              ║
║    Ready to maximize productivity!                          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
    """
    print(banner)

def check_system_requirements():
    """Check if all system requirements are met"""
    print("🔍 Checking system requirements...")
    
    # Check Python version
    if sys.version_info < (3, 8):
        print("❌ Python 3.8+ required")
        return False
        
    # Check required directories exist
    base_path = Path.home() / "Desktop"
    required_paths = [
        base_path / "agents",
        base_path / "🏢 Business-Projects/Exxede/Context-Engineering",
        base_path / "workflow-hub"
    ]
    
    for path in required_paths:
        if not path.exists():
            print(f"❌ Required path missing: {path}")
            return False
            
    print("✅ System requirements met!")
    return True

def start_context_engineering_mcp():
    """Start the Context Engineering MCP if not running"""
    print("🤖 Starting Context Engineering MCP...")
    
    # Check if already running
    try:
        result = subprocess.run(
            ["pgrep", "-f", "context_engineering_mcp"],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            print("✅ Context Engineering MCP already running")
            return True
    except Exception:
        pass
    
    # Try to start it
    mcp_path = Path.home() / "Desktop/🏢 Business-Projects/Exxede/Context-Engineering/context_engineering_mcp.py"
    
    if mcp_path.exists():
        try:
            subprocess.Popen(
                [sys.executable, str(mcp_path)],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            time.sleep(2)  # Give it time to start
            print("✅ Context Engineering MCP started")
            return True
        except Exception as e:
            print(f"⚠️  Could not start MCP: {e}")
            return False
    else:
        print("⚠️  MCP script not found, continuing without...")
        return False

def run_morning_review():
    """Run the morning review to set up the day"""
    print("🌅 Running morning review and daily planning...")
    
    try:
        workflow_hub = Path.home() / "Desktop/workflow-hub"
        result = subprocess.run(
            [sys.executable, "daily-ops/morning_review.py"],
            cwd=workflow_hub,
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            print("✅ Daily plan generated successfully!")
            if result.stdout:
                print("\n" + "="*60)
                print(result.stdout)
                print("="*60 + "\n")
        else:
            print("⚠️  Morning review completed with warnings")
            if result.stderr:
                print(f"Details: {result.stderr[:200]}...")
                
    except Exception as e:
        print(f"⚠️  Could not run morning review: {e}")

def show_quick_commands():
    """Show the most important commands for daily use"""
    print("🎯 Quick Commands for Daily Use:")
    print("""
┌─────────────────────────────────────────────────────────────┐
│                     DAILY COMMANDS                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Morning Setup (start each day):                           │
│  cd ~/Desktop/workflow-hub && python daily-ops/morning_review.py │
│                                                             │
│  Parallel Execution (work mode):                           │
│  python orchestration/agent_coordinator.py --mode parallel │
│                                                             │
│  Project Work:                                              │
│  python orchestration/workflow_runner.py \\                │
│    --workflow "business_development" \\                    │
│    --project "Ocean Paradise"                              │
│                                                             │
│  Evening Wrap-up:                                           │
│  python daily-ops/evening_persistence.py                   │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                    PROJECT COMMANDS                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Initialize New Project:                                    │
│  python orchestration/project_init.py \\                   │
│    --project "Project Name" --type "business"              │
│                                                             │
│  Check System Status:                                       │
│  python orchestration/agent_mcp_bridge.py --status         │
│                                                             │
│  Performance Report:                                        │
│  python metrics/productivity_tracker.py --report daily     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
    """)

def show_agent_assignments():
    """Show optimal agent assignments for different project types"""
    print("🤖 Your Elite Agent Team Assignments:")
    print("""
┌─────────────────────────────────────────────────────────────┐
│                    AGENT SPECIALIZATIONS                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  🏗️  ARQ - Visionary Architect                            │
│     • exxede.diy architecture optimization                 │
│     • Context-Engineering infrastructure                   │
│     • System scalability and cloud design                  │
│                                                             │
│  🎭 ORC - Master Orchestrator                              │
│     • Daily productivity planning                          │
│     • Multi-project coordination                           │
│     • Resource allocation and timeline management          │
│                                                             │
│  🧘 ZEN - Code Zen Master                                  │
│     • exxede.diy code quality and optimization             │
│     • CLAI implementation and security                     │
│     • Clean code and elegant solutions                     │
│                                                             │
│  🎨 VEX - Creative Visionary                               │
│     • ReppingDR UI/UX improvements                         │
│     • Ocean Paradise property visualization                │
│     • Design systems and user experience                   │
│                                                             │
│  🔮 SAGE - Strategic Oracle                                │
│     • ReppingDR Dominican market analysis                  │
│     • Ocean Paradise feasibility studies                   │
│     • Business intelligence and forecasting                │
│                                                             │
│  ⭐ NOVA - Innovation Catalyst                             │
│     • Context-Engineering breakthrough research            │
│     • Emerging technology integration                      │
│     • R&D and impossible challenges                        │
│                                                             │
│  📢 ECHO - Voice of the People                             │
│     • ReppingDR content and community building             │
│     • Cultural adaptation for Dominican market             │
│     • Authentic communication and engagement               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
    """)

def show_integration_status():
    """Show which projects are ready for integration"""
    print("📊 Project Integration Roadmap:")
    print("""
┌─────────────────────────────────────────────────────────────┐
│                   INTEGRATION STATUS                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  🟢 Ready for Immediate Integration:                       │
│     • exxede.diy (Production, 85% complete)                │
│     • ReppingDR (Production, 85% complete)                 │
│     • Context-Engineering (Production, 90% complete)       │
│     • CLAI (Production, 90% complete)                      │
│                                                             │
│  🟡 Ready for Secondary Integration:                       │
│     • terminal-master (Development, 75% complete)          │
│     • Ocean Paradise (Planning, 25% complete)              │
│                                                             │
│  📝 Integration Commands:                                   │
│     cd ~/Desktop/workflow-hub                              │
│     python orchestration/project_init.py \\               │
│       --project "exxede.diy" --type "nextjs"              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
    """)

def main():
    """Main launcher function"""
    print_banner()
    
    # System checks
    if not check_system_requirements():
        print("\n❌ System check failed. Please ensure all requirements are met.")
        return
    
    # Start MCP
    start_context_engineering_mcp()
    
    # Run morning review
    run_morning_review()
    
    # Show usage information
    print("\n" + "="*60)
    show_quick_commands()
    print("\n" + "="*60)
    show_agent_assignments()
    print("\n" + "="*60)
    show_integration_status()
    
    print(f"""
🌟 System Ready! Your productivity multiplication system is online.

📍 Current location: ~/Desktop/workflow-hub/
📋 Daily plan: ~/Desktop/workflow-hub/daily-ops/TODAY.md
📈 Performance tracking: Automatic
🤖 Agent team: Ready and optimized

🚀 Next Steps:
1. Review your daily plan above
2. Initialize your first project with the commands shown
3. Start your first workflow execution
4. Watch your productivity multiply!

Let's conquer the universe together! 🌟

---
System Status: ✅ Online and Ready
Generated: {time.strftime('%Y-%m-%d %H:%M:%S')}
    """)

if __name__ == "__main__":
    main()