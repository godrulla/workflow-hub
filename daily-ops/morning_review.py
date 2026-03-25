#!/usr/bin/env python3
"""
Morning Review System - Start your day with ORC orchestrating all projects
Author: Armando Diaz Silverio
Purpose: Review all active projects and create optimized task delegation plan
"""

import os
import sys
import json
import yaml
from pathlib import Path
from datetime import datetime, date
from typing import Dict, List, Any, Tuple
import logging

# Add parent to path
sys.path.append(str(Path(__file__).parent.parent.parent))

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class MorningReview:
    """Daily morning review and task planning system"""
    
    def __init__(self):
        self.base_path = Path.home() / "Desktop"
        self.workflow_hub = self.base_path / "workflow-hub"
        self.projects_dashboard = self.base_path / "📊 Project-Management-Docs" / "📊 PROJECT_MASTER_DASHBOARD.md"
        
        # Business project paths
        self.project_paths = {
            "exxede.diy": self.base_path / "🏢 Business-Projects" / "Exxede" / "exxede.diy",
            "ReppingDR": self.base_path / "🏢 Business-Projects" / "ReppingDR",
            "Context-Engineering": self.base_path / "🏢 Business-Projects" / "Exxede" / "Context-Engineering",
            "CLAI": self.base_path / "🤖 AI-ML-Projects" / "clai",
            "terminal-master": self.base_path / "🤖 AI-ML-Projects" / "terminal-master",
            "Ocean Paradise": self.base_path / "🏢 Business-Projects" / "Ocean-Paradise",
        }
        
        self.today = date.today()
        self.review_data = {
            "date": self.today.isoformat(),
            "projects": {},
            "tasks": [],
            "agent_assignments": {},
            "priorities": []
        }
        
    def scan_active_projects(self) -> List[Dict[str, Any]]:
        """Scan all active projects and their current status"""
        active_projects = []
        
        for project_name, project_path in self.project_paths.items():
            if project_path.exists():
                project_info = {
                    "name": project_name,
                    "path": str(project_path),
                    "has_context": (project_path / ".context_project.yaml").exists(),
                    "last_modified": None,
                    "priority": self.determine_priority(project_name),
                    "status": "active"
                }
                
                # Get last modified time
                try:
                    for item in project_path.rglob("*"):
                        if item.is_file() and not str(item).startswith('.'):
                            mtime = datetime.fromtimestamp(item.stat().st_mtime)
                            if project_info["last_modified"] is None or mtime > project_info["last_modified"]:
                                project_info["last_modified"] = mtime
                except Exception as e:
                    logger.warning(f"Error scanning {project_name}: {e}")
                    
                active_projects.append(project_info)
                
        # Sort by priority and last modified
        active_projects.sort(key=lambda x: (x["priority"], x["last_modified"] or datetime.min), reverse=True)
        
        return active_projects
        
    def determine_priority(self, project_name: str) -> int:
        """Determine project priority based on business impact"""
        priority_map = {
            "exxede.diy": 5,  # Critical - Production
            "ReppingDR": 5,   # Critical - Production
            "Context-Engineering": 4,  # High - Infrastructure
            "CLAI": 4,        # High - Production AI
            "terminal-master": 3,  # Medium - Development
            "Ocean Paradise": 3,   # Medium - Planning
        }
        return priority_map.get(project_name, 2)
        
    def analyze_project_needs(self, project: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Analyze what each project needs today"""
        tasks = []
        project_name = project["name"]
        
        # Standard daily tasks by project type
        if project_name == "exxede.diy":
            tasks.extend([
                {
                    "project": project_name,
                    "task": "Review deployment status and metrics",
                    "agent": "ORC",
                    "priority": 5,
                    "estimated_time": 30
                },
                {
                    "project": project_name,
                    "task": "Check for critical bugs or issues",
                    "agent": "ZEN",
                    "priority": 5,
                    "estimated_time": 45
                }
            ])
            
        elif project_name == "ReppingDR":
            tasks.extend([
                {
                    "project": project_name,
                    "task": "Update tourism content and offerings",
                    "agent": "ECHO",
                    "priority": 4,
                    "estimated_time": 60
                },
                {
                    "project": project_name,
                    "task": "Analyze market opportunities",
                    "agent": "SAGE",
                    "priority": 4,
                    "estimated_time": 45
                }
            ])
            
        elif project_name == "Context-Engineering":
            tasks.extend([
                {
                    "project": project_name,
                    "task": "Optimize MCP performance and context fields",
                    "agent": "ARQ",
                    "priority": 4,
                    "estimated_time": 60
                },
                {
                    "project": project_name,
                    "task": "Test new protocol shells",
                    "agent": "NOVA",
                    "priority": 3,
                    "estimated_time": 45
                }
            ])
            
        elif project_name == "Ocean Paradise":
            tasks.extend([
                {
                    "project": project_name,
                    "task": "Market analysis for real estate opportunity",
                    "agent": "SAGE",
                    "priority": 3,
                    "estimated_time": 90
                },
                {
                    "project": project_name,
                    "task": "Design property showcase",
                    "agent": "VEX",
                    "priority": 3,
                    "estimated_time": 60
                }
            ])
            
        # Check for README todos
        readme_path = Path(project["path"]) / "README.md"
        if readme_path.exists():
            content = readme_path.read_text()
            if "TODO" in content or "todo" in content:
                tasks.append({
                    "project": project_name,
                    "task": "Address TODO items in README",
                    "agent": "ORC",
                    "priority": 3,
                    "estimated_time": 30
                })
                
        return tasks
        
    def optimize_agent_allocation(self, all_tasks: List[Dict[str, Any]]) -> Dict[str, List[Dict[str, Any]]]:
        """Optimize task allocation across agents for parallel execution"""
        agent_queues = {
            "ARQ": [],
            "ORC": [],
            "ZEN": [],
            "VEX": [],
            "SAGE": [],
            "NOVA": [],
            "ECHO": []
        }
        
        # Sort tasks by priority
        all_tasks.sort(key=lambda x: x["priority"], reverse=True)
        
        # Allocate tasks to agents
        for task in all_tasks:
            agent = task["agent"]
            if agent in agent_queues:
                agent_queues[agent].append(task)
                
        # Balance workload if needed
        max_tasks_per_agent = 3
        for agent, tasks in agent_queues.items():
            if len(tasks) > max_tasks_per_agent:
                # Move lower priority tasks to ORC for delegation
                overflow = tasks[max_tasks_per_agent:]
                agent_queues[agent] = tasks[:max_tasks_per_agent]
                for task in overflow:
                    task["delegated_from"] = agent
                    task["agent"] = "ORC"
                    agent_queues["ORC"].append(task)
                    
        return agent_queues
        
    def generate_daily_plan(self) -> str:
        """Generate the daily execution plan"""
        # Scan active projects
        active_projects = self.scan_active_projects()
        self.review_data["projects"] = {p["name"]: p for p in active_projects}
        
        # Analyze needs for each project
        all_tasks = []
        for project in active_projects:
            tasks = self.analyze_project_needs(project)
            all_tasks.extend(tasks)
            
        self.review_data["tasks"] = all_tasks
        
        # Optimize agent allocation
        agent_assignments = self.optimize_agent_allocation(all_tasks)
        self.review_data["agent_assignments"] = agent_assignments
        
        # Generate plan document
        plan = f"""# 📅 Daily Productivity Plan
**Date**: {self.today.strftime('%A, %B %d, %Y')}
**Generated**: {datetime.now().strftime('%H:%M')}

## 🎯 Today's Focus

### Active Projects ({len(active_projects)})
"""
        
        for project in active_projects[:5]:  # Top 5 projects
            last_mod = project["last_modified"].strftime('%b %d %H:%M') if project["last_modified"] else "Unknown"
            plan += f"- **{project['name']}** (Priority: {project['priority']}/5) - Last activity: {last_mod}\n"
            
        plan += f"\n### Total Tasks: {len(all_tasks)}\n\n"
        
        plan += "## 🤖 Agent Assignments\n\n"
        
        total_time = 0
        for agent, tasks in agent_assignments.items():
            if tasks:
                agent_time = sum(t.get("estimated_time", 30) for t in tasks)
                total_time += agent_time
                plan += f"### {agent} ({len(tasks)} tasks, ~{agent_time} min)\n"
                for task in tasks:
                    priority_emoji = "🔴" if task["priority"] >= 4 else "🟡" if task["priority"] >= 3 else "🟢"
                    plan += f"- {priority_emoji} [{task['project']}] {task['task']}\n"
                plan += "\n"
                
        plan += f"## ⏱️ Time Estimates\n"
        plan += f"- **Total estimated time**: {total_time} minutes ({total_time/60:.1f} hours)\n"
        plan += f"- **Parallel execution time**: ~{total_time/3:.0f} minutes (with 3x parallelization)\n"
        plan += f"- **Expected completion**: {(datetime.now().hour + int(total_time/180))%24}:00\n\n"
        
        plan += "## 🚀 Execution Commands\n\n"
        plan += "```bash\n"
        plan += "# Start parallel execution\n"
        plan += "cd ~/Desktop/workflow-hub\n"
        plan += "python orchestration/agent_coordinator.py --mode parallel --plan today\n"
        plan += "```\n\n"
        
        plan += "## 📊 Success Metrics\n"
        plan += "- [ ] All critical tasks (Priority 5) completed\n"
        plan += "- [ ] At least 80% of tasks completed\n"
        plan += "- [ ] Context preserved for tomorrow\n"
        plan += "- [ ] No blocking issues remaining\n\n"
        
        plan += "---\n*Let's conquer the universe together! 🌟*"
        
        return plan
        
    def save_daily_plan(self, plan: str):
        """Save the daily plan"""
        # Save to workflow hub
        daily_plans_dir = self.workflow_hub / "daily-ops" / "plans"
        daily_plans_dir.mkdir(parents=True, exist_ok=True)
        
        plan_file = daily_plans_dir / f"{self.today.isoformat()}_plan.md"
        plan_file.write_text(plan)
        
        # Save review data as JSON
        data_file = daily_plans_dir / f"{self.today.isoformat()}_data.json"
        with open(data_file, 'w') as f:
            json.dump(self.review_data, f, indent=2, default=str)
            
        # Create symlink to today's plan
        today_link = self.workflow_hub / "daily-ops" / "TODAY.md"
        if today_link.exists():
            today_link.unlink()
        today_link.symlink_to(plan_file)
        
        logger.info(f"Daily plan saved to {plan_file}")
        logger.info(f"Access today's plan at {today_link}")
        
def main():
    """Main execution"""
    print("\n🌅 Good morning, Armando! Starting daily review with ORC...\n")
    
    review = MorningReview()
    plan = review.generate_daily_plan()
    
    print(plan)
    
    review.save_daily_plan(plan)
    
    print("\n✅ Daily plan generated and saved!")
    print(f"📄 View at: ~/Desktop/workflow-hub/daily-ops/TODAY.md")
    print("\n🚀 Ready to conquer the universe together!\n")

if __name__ == "__main__":
    main()