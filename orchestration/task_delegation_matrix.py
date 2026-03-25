#!/usr/bin/env python3
"""
Task Delegation Matrix - Intelligent task routing and agent optimization
Author: Armando Diaz Silverio
Purpose: Optimize task delegation based on agent capabilities, workload, and context
"""

import json
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

@dataclass
class AgentMetrics:
    """Performance metrics for each agent"""
    success_rate: float = 0.0
    avg_completion_time: float = 0.0
    current_workload: int = 0
    specialization_score: float = 0.0
    availability: bool = True
    last_active: Optional[datetime] = None

class TaskDelegationMatrix:
    """Smart task delegation system with performance optimization"""
    
    def __init__(self):
        # Task type to capability mapping
        self.task_capabilities = {
            "architecture": ["system_design", "scalability", "cloud", "infrastructure"],
            "coding": ["algorithms", "implementation", "optimization", "testing"],
            "design": ["ui_ux", "user_experience", "creativity", "visual"],
            "strategy": ["market_analysis", "planning", "intelligence", "forecasting"],
            "innovation": ["breakthrough", "emerging_tech", "r_and_d", "creativity"],
            "coordination": ["orchestration", "management", "workflow", "delegation"],
            "content": ["communication", "culture", "community", "marketing"],
            "analysis": ["data", "metrics", "performance", "optimization"],
            "testing": ["quality_assurance", "validation", "debugging"],
            "deployment": ["infrastructure", "monitoring", "production"],
            "research": ["investigation", "analysis", "intelligence"],
            "planning": ["strategy", "timeline", "resources", "coordination"]
        }
        
        # Agent capability scores (dynamically updated)
        self.agent_metrics = {
            "ARQ": AgentMetrics(success_rate=0.95, specialization_score=0.98),
            "ORC": AgentMetrics(success_rate=0.97, specialization_score=0.96),
            "ZEN": AgentMetrics(success_rate=0.93, specialization_score=0.94),
            "VEX": AgentMetrics(success_rate=0.92, specialization_score=0.93),
            "SAGE": AgentMetrics(success_rate=0.94, specialization_score=0.95),
            "NOVA": AgentMetrics(success_rate=0.91, specialization_score=0.92),
            "ECHO": AgentMetrics(success_rate=0.90, specialization_score=0.91)
        }
        
        # Task delegation rules
        self.delegation_rules = self._build_delegation_matrix()
        
        # Performance history
        self.performance_history = []
        
    def _build_delegation_matrix(self) -> Dict[str, Dict[str, float]]:
        """Build the task delegation scoring matrix"""
        return {
            # System Architecture & Infrastructure
            "architecture": {
                "ARQ": 1.0, "ORC": 0.3, "ZEN": 0.4, "VEX": 0.2, 
                "SAGE": 0.3, "NOVA": 0.5, "ECHO": 0.1
            },
            "system_design": {
                "ARQ": 1.0, "ORC": 0.4, "ZEN": 0.6, "VEX": 0.3,
                "SAGE": 0.4, "NOVA": 0.6, "ECHO": 0.1
            },
            "scalability": {
                "ARQ": 1.0, "ORC": 0.5, "ZEN": 0.7, "VEX": 0.2,
                "SAGE": 0.3, "NOVA": 0.4, "ECHO": 0.1
            },
            "infrastructure": {
                "ARQ": 1.0, "ORC": 0.6, "ZEN": 0.5, "VEX": 0.1,
                "SAGE": 0.2, "NOVA": 0.3, "ECHO": 0.1
            },
            
            # Development & Code Quality
            "coding": {
                "ARQ": 0.6, "ORC": 0.3, "ZEN": 1.0, "VEX": 0.4,
                "SAGE": 0.2, "NOVA": 0.7, "ECHO": 0.2
            },
            "implementation": {
                "ARQ": 0.7, "ORC": 0.4, "ZEN": 1.0, "VEX": 0.5,
                "SAGE": 0.3, "NOVA": 0.6, "ECHO": 0.3
            },
            "refactoring": {
                "ARQ": 0.5, "ORC": 0.2, "ZEN": 1.0, "VEX": 0.3,
                "SAGE": 0.1, "NOVA": 0.4, "ECHO": 0.1
            },
            "optimization": {
                "ARQ": 0.8, "ORC": 0.4, "ZEN": 1.0, "VEX": 0.3,
                "SAGE": 0.3, "NOVA": 0.5, "ECHO": 0.2
            },
            "testing": {
                "ARQ": 0.4, "ORC": 0.5, "ZEN": 1.0, "VEX": 0.3,
                "SAGE": 0.2, "NOVA": 0.4, "ECHO": 0.2
            },
            
            # Design & User Experience
            "design": {
                "ARQ": 0.2, "ORC": 0.3, "ZEN": 0.3, "VEX": 1.0,
                "SAGE": 0.3, "NOVA": 0.6, "ECHO": 0.7
            },
            "ui_ux": {
                "ARQ": 0.2, "ORC": 0.2, "ZEN": 0.3, "VEX": 1.0,
                "SAGE": 0.2, "NOVA": 0.4, "ECHO": 0.6
            },
            "user_experience": {
                "ARQ": 0.3, "ORC": 0.4, "ZEN": 0.3, "VEX": 1.0,
                "SAGE": 0.5, "NOVA": 0.4, "ECHO": 0.8
            },
            "prototyping": {
                "ARQ": 0.4, "ORC": 0.3, "ZEN": 0.6, "VEX": 1.0,
                "SAGE": 0.2, "NOVA": 0.7, "ECHO": 0.4
            },
            
            # Strategy & Analysis
            "strategy": {
                "ARQ": 0.4, "ORC": 0.8, "ZEN": 0.2, "VEX": 0.3,
                "SAGE": 1.0, "NOVA": 0.6, "ECHO": 0.4
            },
            "market_analysis": {
                "ARQ": 0.3, "ORC": 0.5, "ZEN": 0.2, "VEX": 0.3,
                "SAGE": 1.0, "NOVA": 0.4, "ECHO": 0.5
            },
            "business_intelligence": {
                "ARQ": 0.3, "ORC": 0.6, "ZEN": 0.3, "VEX": 0.2,
                "SAGE": 1.0, "NOVA": 0.5, "ECHO": 0.4
            },
            "forecasting": {
                "ARQ": 0.2, "ORC": 0.4, "ZEN": 0.2, "VEX": 0.1,
                "SAGE": 1.0, "NOVA": 0.6, "ECHO": 0.2
            },
            
            # Innovation & Research
            "innovation": {
                "ARQ": 0.5, "ORC": 0.3, "ZEN": 0.4, "VEX": 0.6,
                "SAGE": 0.4, "NOVA": 1.0, "ECHO": 0.3
            },
            "research": {
                "ARQ": 0.4, "ORC": 0.4, "ZEN": 0.3, "VEX": 0.3,
                "SAGE": 0.8, "NOVA": 1.0, "ECHO": 0.4
            },
            "emerging_tech": {
                "ARQ": 0.7, "ORC": 0.2, "ZEN": 0.5, "VEX": 0.4,
                "SAGE": 0.3, "NOVA": 1.0, "ECHO": 0.2
            },
            "breakthrough": {
                "ARQ": 0.4, "ORC": 0.2, "ZEN": 0.3, "VEX": 0.5,
                "SAGE": 0.3, "NOVA": 1.0, "ECHO": 0.3
            },
            
            # Coordination & Management
            "coordination": {
                "ARQ": 0.6, "ORC": 1.0, "ZEN": 0.4, "VEX": 0.4,
                "SAGE": 0.7, "NOVA": 0.3, "ECHO": 0.5
            },
            "orchestration": {
                "ARQ": 0.5, "ORC": 1.0, "ZEN": 0.3, "VEX": 0.3,
                "SAGE": 0.5, "NOVA": 0.3, "ECHO": 0.4
            },
            "workflow": {
                "ARQ": 0.7, "ORC": 1.0, "ZEN": 0.5, "VEX": 0.4,
                "SAGE": 0.6, "NOVA": 0.4, "ECHO": 0.5
            },
            "delegation": {
                "ARQ": 0.4, "ORC": 1.0, "ZEN": 0.3, "VEX": 0.3,
                "SAGE": 0.6, "NOVA": 0.2, "ECHO": 0.4
            },
            
            # Communication & Community
            "content": {
                "ARQ": 0.2, "ORC": 0.4, "ZEN": 0.3, "VEX": 0.6,
                "SAGE": 0.4, "NOVA": 0.3, "ECHO": 1.0
            },
            "communication": {
                "ARQ": 0.3, "ORC": 0.6, "ZEN": 0.4, "VEX": 0.5,
                "SAGE": 0.5, "NOVA": 0.4, "ECHO": 1.0
            },
            "community": {
                "ARQ": 0.1, "ORC": 0.4, "ZEN": 0.2, "VEX": 0.5,
                "SAGE": 0.3, "NOVA": 0.2, "ECHO": 1.0
            },
            "marketing": {
                "ARQ": 0.2, "ORC": 0.5, "ZEN": 0.2, "VEX": 0.7,
                "SAGE": 0.6, "NOVA": 0.4, "ECHO": 1.0
            },
            "culture": {
                "ARQ": 0.1, "ORC": 0.3, "ZEN": 0.2, "VEX": 0.4,
                "SAGE": 0.4, "NOVA": 0.2, "ECHO": 1.0
            }
        }
        
    def calculate_delegation_score(
        self,
        task_type: str,
        agent: str,
        context: Dict[str, Any] = None
    ) -> float:
        """Calculate delegation score for a specific agent and task"""
        
        # Base capability score
        base_score = self.delegation_rules.get(task_type, {}).get(agent, 0.0)
        
        # Agent performance metrics
        metrics = self.agent_metrics.get(agent, AgentMetrics())
        
        # Adjust for success rate
        performance_factor = metrics.success_rate
        
        # Adjust for current workload (prefer less busy agents)
        workload_factor = max(0.1, 1.0 - (metrics.current_workload * 0.2))
        
        # Adjust for availability
        availability_factor = 1.0 if metrics.availability else 0.1
        
        # Context adjustments
        context_factor = 1.0
        if context:
            # Priority adjustment
            priority = context.get("priority", 3)
            if priority >= 4 and base_score >= 0.8:
                context_factor += 0.2  # Boost high-capability agents for critical tasks
                
            # Project type adjustment
            project_type = context.get("project_type", "")
            if project_type == "business" and agent == "SAGE":
                context_factor += 0.1
            elif project_type == "technical" and agent in ["ARQ", "ZEN"]:
                context_factor += 0.1
            elif project_type == "creative" and agent in ["VEX", "ECHO"]:
                context_factor += 0.1
                
        # Calculate final score
        final_score = (
            base_score * 
            performance_factor * 
            workload_factor * 
            availability_factor * 
            context_factor
        )
        
        return min(1.0, final_score)  # Cap at 1.0
        
    def delegate_task(
        self,
        task_type: str,
        description: str,
        context: Dict[str, Any] = None,
        exclude_agents: List[str] = None
    ) -> Tuple[str, float, Dict[str, float]]:
        """
        Delegate a task to the best available agent
        Returns: (selected_agent, confidence_score, all_scores)
        """
        
        exclude_agents = exclude_agents or []
        agent_scores = {}
        
        # Calculate scores for all agents
        for agent in self.agent_metrics.keys():
            if agent not in exclude_agents:
                score = self.calculate_delegation_score(task_type, agent, context)
                agent_scores[agent] = score
                
        # Select best agent
        if not agent_scores:
            return "ORC", 0.5, {}  # Default fallback
            
        best_agent = max(agent_scores, key=agent_scores.get)
        best_score = agent_scores[best_agent]
        
        # Update agent workload
        self.agent_metrics[best_agent].current_workload += 1
        self.agent_metrics[best_agent].last_active = datetime.now()
        
        logger.info(f"Delegated '{task_type}' to {best_agent} (score: {best_score:.2f})")
        
        return best_agent, best_score, agent_scores
        
    def delegate_batch(
        self,
        tasks: List[Dict[str, Any]],
        optimize_for: str = "performance"  # "performance", "speed", "balance"
    ) -> List[Dict[str, Any]]:
        """
        Delegate a batch of tasks optimally
        optimize_for options:
        - "performance": Prioritize best capability match
        - "speed": Prioritize parallel execution
        - "balance": Balance performance and parallelization
        """
        
        delegated_tasks = []
        
        # Sort tasks by priority
        tasks_sorted = sorted(tasks, key=lambda x: x.get("priority", 3), reverse=True)
        
        for task in tasks_sorted:
            task_type = task.get("type", "general")
            description = task.get("description", "")
            context = task.get("context", {})
            
            # For speed optimization, avoid overloading agents
            exclude_agents = []
            if optimize_for == "speed":
                overloaded = [
                    agent for agent, metrics in self.agent_metrics.items()
                    if metrics.current_workload >= 2
                ]
                exclude_agents.extend(overloaded)
                
            agent, score, all_scores = self.delegate_task(
                task_type, description, context, exclude_agents
            )
            
            # Add delegation info to task
            delegated_task = task.copy()
            delegated_task.update({
                "assigned_agent": agent,
                "delegation_score": score,
                "all_scores": all_scores,
                "delegated_at": datetime.now().isoformat()
            })
            
            delegated_tasks.append(delegated_task)
            
        return delegated_tasks
        
    def update_performance(self, agent: str, success: bool, completion_time: float):
        """Update agent performance metrics based on task completion"""
        
        metrics = self.agent_metrics[agent]
        
        # Update success rate (exponential moving average)
        alpha = 0.1  # Learning rate
        if success:
            metrics.success_rate = metrics.success_rate * (1 - alpha) + alpha
        else:
            metrics.success_rate = metrics.success_rate * (1 - alpha)
            
        # Update completion time
        if metrics.avg_completion_time == 0:
            metrics.avg_completion_time = completion_time
        else:
            metrics.avg_completion_time = (
                metrics.avg_completion_time * (1 - alpha) + 
                completion_time * alpha
            )
            
        # Decrease workload
        metrics.current_workload = max(0, metrics.current_workload - 1)
        
        # Record performance
        self.performance_history.append({
            "agent": agent,
            "success": success,
            "completion_time": completion_time,
            "timestamp": datetime.now().isoformat()
        })
        
        logger.info(f"Updated {agent} performance: success={success}, time={completion_time}")
        
    def get_performance_report(self) -> Dict[str, Any]:
        """Generate a performance report for all agents"""
        
        report = {
            "timestamp": datetime.now().isoformat(),
            "agents": {},
            "summary": {
                "total_tasks_completed": len(self.performance_history),
                "avg_success_rate": 0.0,
                "most_active_agent": "",
                "best_performer": ""
            }
        }
        
        # Agent-specific metrics
        for agent, metrics in self.agent_metrics.items():
            agent_tasks = [h for h in self.performance_history if h["agent"] == agent]
            
            report["agents"][agent] = {
                "success_rate": metrics.success_rate,
                "avg_completion_time": metrics.avg_completion_time,
                "current_workload": metrics.current_workload,
                "total_tasks": len(agent_tasks),
                "availability": metrics.availability,
                "last_active": metrics.last_active.isoformat() if metrics.last_active else None
            }
            
        # Calculate summary statistics
        success_rates = [m.success_rate for m in self.agent_metrics.values()]
        report["summary"]["avg_success_rate"] = sum(success_rates) / len(success_rates)
        
        task_counts = [len([h for h in self.performance_history if h["agent"] == agent]) 
                      for agent in self.agent_metrics.keys()]
        if task_counts:
            most_active_idx = task_counts.index(max(task_counts))
            report["summary"]["most_active_agent"] = list(self.agent_metrics.keys())[most_active_idx]
            
        best_performer_idx = success_rates.index(max(success_rates))
        report["summary"]["best_performer"] = list(self.agent_metrics.keys())[best_performer_idx]
        
        return report
        
    def save_performance_data(self, filepath: str):
        """Save performance data to file"""
        data = {
            "agent_metrics": {
                agent: {
                    "success_rate": metrics.success_rate,
                    "avg_completion_time": metrics.avg_completion_time,
                    "current_workload": metrics.current_workload,
                    "specialization_score": metrics.specialization_score,
                    "availability": metrics.availability,
                    "last_active": metrics.last_active.isoformat() if metrics.last_active else None
                }
                for agent, metrics in self.agent_metrics.items()
            },
            "performance_history": self.performance_history,
            "last_updated": datetime.now().isoformat()
        }
        
        with open(filepath, 'w') as f:
            json.dump(data, f, indent=2)
            
        logger.info(f"Performance data saved to {filepath}")

# Example usage and testing
def main():
    """Example usage of the delegation matrix"""
    
    matrix = TaskDelegationMatrix()
    
    # Example tasks
    example_tasks = [
        {
            "type": "architecture",
            "description": "Design microservices architecture",
            "priority": 5,
            "context": {"project_type": "technical"}
        },
        {
            "type": "ui_ux",
            "description": "Create user interface mockups",
            "priority": 4,
            "context": {"project_type": "creative"}
        },
        {
            "type": "market_analysis",
            "description": "Analyze Dominican Republic market opportunity",
            "priority": 4,
            "context": {"project_type": "business", "region": "DR"}
        }
    ]
    
    # Delegate tasks
    delegated = matrix.delegate_batch(example_tasks, optimize_for="balance")
    
    # Print results
    print("Task Delegation Results:")
    print("=" * 50)
    for task in delegated:
        print(f"Task: {task['description']}")
        print(f"Assigned to: {task['assigned_agent']} (score: {task['delegation_score']:.2f})")
        print(f"Priority: {task['priority']}")
        print("-" * 30)
        
    # Generate performance report
    report = matrix.get_performance_report()
    print(f"\nPerformance Report:")
    print(f"Best Performer: {report['summary']['best_performer']}")
    print(f"Most Active: {report['summary']['most_active_agent']}")
    print(f"Average Success Rate: {report['summary']['avg_success_rate']:.2f}")

if __name__ == "__main__":
    main()