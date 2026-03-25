#!/usr/bin/env python3
"""
Setup Virtual Environment for Workflow Hub GUI
Handles the externally-managed-environment issue on macOS
"""

import os
import sys
import subprocess
import venv
from pathlib import Path

def create_virtual_environment():
    """Create a virtual environment for the project"""
    project_dir = Path(__file__).parent
    venv_dir = project_dir / "venv"
    
    print("🔧 Creating virtual environment...")
    
    # Remove existing venv if it exists
    if venv_dir.exists():
        import shutil
        shutil.rmtree(venv_dir)
    
    # Create new virtual environment
    venv.create(venv_dir, with_pip=True)
    
    # Get the python executable path in the venv
    if sys.platform == "win32":
        python_exe = venv_dir / "Scripts" / "python.exe"
        pip_exe = venv_dir / "Scripts" / "pip.exe"
    else:
        python_exe = venv_dir / "bin" / "python"
        pip_exe = venv_dir / "bin" / "pip"
    
    print("✅ Virtual environment created")
    
    # Install required packages
    packages = [
        "websockets>=11.0.3",
        "psutil>=5.9.0", 
        "pyyaml>=6.0",
        "pydantic>=2.0.0"
    ]
    
    print("📦 Installing Python packages...")
    for package in packages:
        print(f"   Installing {package}...")
        result = subprocess.run([str(pip_exe), "install", package], 
                              capture_output=True, text=True)
        if result.returncode != 0:
            print(f"❌ Failed to install {package}: {result.stderr}")
            return False
    
    print("✅ All packages installed successfully")
    
    # Create activation script
    create_activation_scripts(project_dir, python_exe)
    
    return True

def create_activation_scripts(project_dir, python_exe):
    """Create convenient activation scripts"""
    
    # Create start script that uses the venv
    start_script = project_dir / "start_gui_with_venv.py"
    start_script.write_text(f'''#!/usr/bin/env python3
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
''')
    
    # Make it executable
    start_script.chmod(0o755)
    
    print(f"✅ Created launcher script: {start_script}")
    
    # Create shell script for easy terminal usage
    shell_script = project_dir / "start_gui.sh"
    shell_script.write_text(f'''#!/bin/bash
# Workflow Hub GUI Launcher Shell Script

cd "{project_dir}"
"{python_exe}" start_gui_system.py "$@"
''')
    shell_script.chmod(0o755)
    
    print(f"✅ Created shell script: {shell_script}")

if __name__ == "__main__":
    if create_virtual_environment():
        print("""
🎉 Setup Complete!

You can now run the Workflow Hub GUI using:

Option 1 (Recommended):
  python3 start_gui_with_venv.py

Option 2 (Shell script):
  ./start_gui.sh

Option 3 (Direct venv):
  source venv/bin/activate
  python start_gui_system.py

Next step: Create macOS app bundle for double-click launching!
        """)
    else:
        print("❌ Setup failed. Please check the error messages above.")