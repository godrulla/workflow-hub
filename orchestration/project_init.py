#!/usr/bin/env python3
"""
Project Initialization Protocol
Automatically detect project type and spawn appropriate agent teams
Author: Armando Diaz Silverio
"""

import os
import sys
import json
import yaml
import asyncio
import argparse
from pathlib import Path
from typing import Dict, List, Any, Optional
from datetime import datetime
import logging

# Add parent to path
sys.path.append(str(Path(__file__).parent.parent.parent))

from agent_mcp_bridge import AgentMCPBridge, Task

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class ProjectInitializer:
    """Initialize new projects with appropriate agent teams and workflows"""
    
    def __init__(self):
        self.bridge = AgentMCPBridge()
        self.base_path = Path.home() / "Desktop"
        self.workflow_hub = self.base_path / "workflow-hub"
        
        # Project type detection patterns
        self.project_patterns = {
            "node_js": ["package.json", "node_modules"],
            "python": ["requirements.txt", "pyproject.toml", "setup.py"],
            "react": ["package.json", "src/App.tsx", "src/App.jsx"],
            "nextjs": ["next.config.js", "pages", "app"],
            "rust": ["Cargo.toml", "src/main.rs"],
            "go": ["go.mod", "main.go"],
            "business": ["business_plan", "market_analysis", "strategy"],
            "real_estate": ["property", "listing", "valuation"],
            "ai_ml": ["model", "training", "dataset", ".ipynb"]
        }
        
        # Agent team configurations by project type
        self.agent_teams = {
            "node_js": ["ZEN", "ARQ", "VEX"],
            "python": ["ZEN", "ARQ", "NOVA"],
            "react": ["VEX", "ZEN", "ARQ"],
            "nextjs": ["VEX", "ZEN", "ARQ", "ECHO"],
            "rust": ["ZEN", "ARQ"],
            "go": ["ZEN", "ARQ"],
            "business": ["SAGE", "NOVA", "ORC"],
            "real_estate": ["SAGE", "ORC"],
            "ai_ml": ["NOVA", "ZEN", "ARQ"],
            "default": ["ORC", "SAGE"]
        }
        
        # Workflow mappings
        self.workflow_mappings = {
            "business": "business_development",
            "node_js": "product_development",
            "python": "product_development",
            "react": "product_development",
            "nextjs": "product_development",
            "real_estate": "business_development",
            "ai_ml": "product_development"
        }
        
    def detect_project_type(self, project_path: Path) -> str:
        """Detect project type based on files and structure"""
        if not project_path.exists():
            return "unknown"
            
        # Check for specific file patterns
        for project_type, patterns in self.project_patterns.items():
            for pattern in patterns:
                if (project_path / pattern).exists():
                    logger.info(f"Detected project type: {project_type}")
                    return project_type
                    
                # Check if pattern is in any file name
                if any(pattern in str(f) for f in project_path.iterdir() if f.is_file()):
                    logger.info(f"Detected project type: {project_type}")
                    return project_type
                    
        return "default"
        
    def analyze_project_context(self, project_path: Path) -> Dict[str, Any]:
        """Analyze project to build initial context"""
        context = {
            "project_path": str(project_path),
            "project_name": project_path.name,
            "created_at": datetime.now().isoformat(),
            "files": [],
            "directories": [],
            "readme_content": None,
            "dependencies": {},
            "configuration": {}
        }
        
        # Scan project structure
        try:
            for item in project_path.iterdir():
                if item.is_file():
                    context["files"].append(item.name)
                    
                    # Extract README content
                    if item.name.lower() in ["readme.md", "readme.txt"]:
                        context["readme_content"] = item.read_text()[:1000]
                        
                    # Extract dependencies
                    if item.name == "package.json":
                        with open(item) as f:
                            pkg = json.load(f)
                            context["dependencies"]["npm"] = pkg.get("dependencies", {})
                            
                    elif item.name == "requirements.txt":
                        context["dependencies"]["python"] = item.read_text().splitlines()
                        
                elif item.is_dir() and not item.name.startswith('.'):
                    context["directories"].append(item.name)
                    
        except Exception as e:
            logger.error(f"Error analyzing project: {e}")
            
        return context
        
    async def initialize_project(
        self,
        project_name: str,
        project_type: Optional[str] = None,
        project_path: Optional[Path] = None
    ) -> Dict[str, Any]:
        """Initialize a new project with appropriate agent team"""
        
        # Determine project path
        if project_path is None:
            # Check common project locations
            possible_paths = [
                self.base_path / "🏢 Business-Projects" / project_name,
                self.base_path / "🤖 AI-ML-Projects" / project_name,
                self.base_path / "🛠️ Dev-Tools" / project_name,
                self.base_path / project_name
            ]
            
            for path in possible_paths:
                if path.exists():
                    project_path = path
                    break
            else:
                # Create new project in appropriate category
                if project_type == "business":
                    project_path = self.base_path / "🏢 Business-Projects" / project_name
                elif project_type in ["ai_ml", "ai", "ml"]:
                    project_path = self.base_path / "🤖 AI-ML-Projects" / project_name
                else:
                    project_path = self.base_path / "🛠️ Dev-Tools" / project_name
                    
                project_path.mkdir(parents=True, exist_ok=True)
                
        # Auto-detect project type if not specified
        if project_type is None:
            project_type = self.detect_project_type(project_path)
            
        logger.info(f"Initializing project: {project_name} (type: {project_type})")
        
        # Analyze project context
        context = self.analyze_project_context(project_path)
        context["project_type"] = project_type
        
        # Initialize bridge
        await self.bridge.initialize()
        
        # Get agent team for this project type
        agent_team = self.agent_teams.get(project_type, self.agent_teams["default"])
        
        # Create initialization tasks for each agent
        init_tasks = []
        for agent in agent_team:
            task = Task(
                id=f"init_{project_name}_{agent}",
                type="initialization",
                description=f"Initialize {project_name} project context for {agent}",
                priority=5,
                required_capabilities=self.bridge.agents[agent].specialization,
                context=context
            )
            init_tasks.append(task)
            
        # Execute initialization tasks in parallel
        logger.info(f"Spawning agent team: {', '.join(agent_team)}")
        results = await self.bridge.parallel_execute(init_tasks)
        
        # Create project configuration
        project_config = {
            "project": {
                "name": project_name,
                "type": project_type,
                "path": str(project_path),
                "initialized": datetime.now().isoformat(),
                "agent_team": agent_team,
                "workflow": self.workflow_mappings.get(project_type, "custom")
            },
            "context": context,
            "agents": {
                agent: {
                    "assigned": True,
                    "specialization": self.bridge.agents[agent].specialization,
                    "initialization_complete": True
                }
                for agent in agent_team
            },
            "field_parameters": {
                "decay_rate": 0.03,
                "attractor_threshold": 0.75,
                "resonance_bandwidth": 0.6
            }
        }
        
        # Save project configuration
        config_file = project_path / ".context_project.yaml"
        with open(config_file, 'w') as f:
            yaml.dump(project_config, f, default_flow_style=False)
            
        logger.info(f"Project configuration saved to {config_file}")
        
        # Create project-specific workflow file
        workflow_file = self.workflow_hub / "workflows" / "custom" / f"{project_name}_workflow.yaml"
        workflow_file.parent.mkdir(parents=True, exist_ok=True)
        
        workflow_template = self.create_custom_workflow(project_name, project_type, agent_team)
        with open(workflow_file, 'w') as f:
            yaml.dump(workflow_template, f, default_flow_style=False)
            
        logger.info(f"Custom workflow created at {workflow_file}")
        
        # Create initial README if it doesn't exist
        readme_path = project_path / "README.md"
        if not readme_path.exists():
            readme_content = self.generate_readme(project_name, project_type, agent_team)
            readme_path.write_text(readme_content)
            logger.info("Created initial README.md")
            
        return {
            "status": "success",
            "project": project_name,
            "type": project_type,
            "path": str(project_path),
            "agent_team": agent_team,
            "workflow": self.workflow_mappings.get(project_type, "custom"),
            "config_file": str(config_file),
            "initialization_results": results
        }
        
    def create_custom_workflow(
        self,
        project_name: str,
        project_type: str,
        agent_team: List[str]
    ) -> Dict[str, Any]:
        """Create a custom workflow for the project"""
        return {
            "workflow": {
                "name": f"{project_name}_workflow",
                "description": f"Custom workflow for {project_name} ({project_type})",
                "version": "1.0",
                "created": datetime.now().isoformat(),
                "project_type": project_type
            },
            "stages": [
                {
                    "stage": f"{agent}_stage",
                    "agent": agent,
                    "description": f"{agent} tasks for {project_name}",
                    "tasks": self.get_agent_tasks(agent, project_type)
                }
                for agent in agent_team
            ],
            "parallel_optimization": {
                "enabled": True,
                "max_parallel": min(3, len(agent_team))
            },
            "context_persistence": {
                "enabled": True,
                "auto_save": True
            }
        }
        
    def get_agent_tasks(self, agent: str, project_type: str) -> List[str]:
        """Get default tasks for an agent based on project type"""
        task_mappings = {
            "ARQ": [
                "Design system architecture",
                "Plan scalability strategy",
                "Define technology stack",
                "Create infrastructure plan"
            ],
            "ORC": [
                "Coordinate team activities",
                "Manage project timeline",
                "Allocate resources",
                "Monitor progress"
            ],
            "ZEN": [
                "Implement core functionality",
                "Write clean code",
                "Optimize performance",
                "Create tests"
            ],
            "VEX": [
                "Design user interface",
                "Create user experience flow",
                "Develop design system",
                "Ensure accessibility"
            ],
            "SAGE": [
                "Analyze market opportunity",
                "Develop strategy",
                "Assess competition",
                "Create projections"
            ],
            "NOVA": [
                "Identify innovations",
                "Research new technologies",
                "Generate breakthrough ideas",
                "Evaluate feasibility"
            ],
            "ECHO": [
                "Build community strategy",
                "Create content plan",
                "Design engagement",
                "Plan communication"
            ]
        }
        
        return task_mappings.get(agent, ["Analyze requirements", "Plan execution", "Implement solution"])
        
    def generate_readme(self, project_name: str, project_type: str, agent_team: List[str]) -> str:
        """Generate initial README content"""
        return f"""# {project_name}

## Project Type
{project_type.replace('_', ' ').title()}

## Agent Team
This project is managed by the following Elite Agents:
{chr(10).join(f"- **{agent}**: {', '.join(self.bridge.agents[agent].specialization)}" for agent in agent_team)}

## Project Status
- Initialized: {datetime.now().strftime('%Y-%m-%d %H:%M')}
- Workflow: {self.workflow_mappings.get(project_type, 'custom')}
- Context Engineering: Enabled

## Quick Start
```bash
cd {project_name}
# Project has been initialized with agent team
# Use workflow hub for orchestrated execution
```

## Workflow Execution
```bash
cd ~/Desktop/workflow-hub
python orchestration/workflow_runner.py --project "{project_name}"
```

## Configuration
Project configuration is stored in `.context_project.yaml`

---
*Managed by Agent-MCP Productivity System*"""

async def main():
    """Main execution"""
    parser = argparse.ArgumentParser(description='Initialize a new project with agent team')
    parser.add_argument('--project', required=True, help='Project name')
    parser.add_argument('--type', help='Project type (auto-detected if not specified)')
    parser.add_argument('--path', help='Project path (auto-determined if not specified)')
    
    args = parser.parse_args()
    
    initializer = ProjectInitializer()
    
    # Convert path string to Path object if provided
    project_path = Path(args.path) if args.path else None
    
    result = await initializer.initialize_project(
        project_name=args.project,
        project_type=args.type,
        project_path=project_path
    )
    
    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    asyncio.run(main())