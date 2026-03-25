#!/usr/bin/env python3
"""
Workflow Hub GUI Launcher with Virtual Environment
This script automatically uses the project's virtual environment
"""

import os
import sys
import subprocess
from pathlib import Path

def main():
    project_dir = Path(__file__).parent
    venv_python = project_dir / "venv" / "bin" / "python"
    gui_script = project_dir / "start_gui_system.py"
    
    if not venv_python.exists():
        print("❌ Virtual environment not found. Please run setup_venv.py first.")
        return 1
    
    # Run the GUI system using the virtual environment Python
    os.environ["PYTHONPATH"] = str(project_dir)
    result = subprocess.run([str(venv_python), str(gui_script)])
    return result.returncode

if __name__ == "__main__":
    sys.exit(main())
