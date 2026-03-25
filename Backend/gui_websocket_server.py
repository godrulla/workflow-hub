#!/usr/bin/env python3
"""
GUI WebSocket Server - Real-time communication bridge for macOS GUI
Author: Armando Diaz Silverio
Purpose: Provide real-time data streaming to macOS Workflow Hub GUI
"""

import asyncio
import json
import websockets
import sys
import os
import logging
from datetime import datetime
from typing import Dict, Set, Any, Optional
from pathlib import Path
import threading
import time

# Add workflow-hub to path
sys.path.append(str(Path(__file__).parent.parent))

try:
    from orchestration.agent_mcp_bridge import AgentMCPBridge, Task
    from orchestration.task_delegation_matrix import TaskDelegationMatrix
    from daily_ops.morning_review import MorningReview
except ImportError:
    print("Warning: Could not import workflow-hub modules. Running in standalone mode.")

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class GUIWebSocketServer:
    """WebSocket server for real-time GUI communication"""
    
    def __init__(self, host='localhost', port=8765):
        self.host = host
        self.port = port
        self.clients: Set[websockets.WebSocketServerProtocol] = set()
        
        # Integration with existing system
        self.agent_bridge = None
        self.delegation_matrix = None
        self.morning_review = None
        
        # System state
        self.system_state = {
            "agents": self._get_default_agents(),
            "projects": self._get_default_projects(),
            "token_usage": {
                "total_tokens": 0,
                "session_tokens": 0,
                "agent_breakdown": {},
                "last_updated": datetime.now().isoformat()
            },
            "system_metrics": {
                "cpu_usage": 0.0,
                "memory_usage": 0.0,
                "active_agents": 0,
                "last_updated": datetime.now().isoformat()
            },
            "workflows": []
        }
        
        # Background tasks
        self.update_task = None
        self.running = False
        
    async def start_server(self):
        """Start the WebSocket server"""
        logger.info(f"Starting GUI WebSocket server on {self.host}:{self.port}")
        
        try:
            # Initialize system integrations
            await self._initialize_integrations()
            
            # Start background update task
            self.running = True
            self.update_task = asyncio.create_task(self._background_updates())
            
            # Start WebSocket server
            server = await websockets.serve(
                self.handle_client,
                self.host,
                self.port,
                ping_interval=20,
                ping_timeout=10
            )
            
            logger.info(f"GUI WebSocket server running on ws://{self.host}:{self.port}")
            
            # Keep server running
            await server.wait_closed()
            
        except Exception as e:
            logger.error(f"Failed to start server: {e}")
            raise
            
    async def stop_server(self):
        """Stop the WebSocket server"""
        self.running = False
        
        if self.update_task:
            self.update_task.cancel()
            
        # Disconnect all clients
        if self.clients:
            await asyncio.gather(
                *[client.close() for client in self.clients],
                return_exceptions=True
            )
        
        logger.info("GUI WebSocket server stopped")
        
    async def handle_client(self, websocket):
        """Handle individual client connections"""
        client_addr = websocket.remote_address
        logger.info(f"New GUI client connected: {client_addr}")
        
        self.clients.add(websocket)
        
        try:
            # Send initial system state
            await self._send_initial_state(websocket)
            
            # Handle incoming messages
            async for message in websocket:
                try:
                    await self._handle_message(websocket, message)
                except Exception as e:
                    logger.error(f"Error handling message from {client_addr}: {e}")
                    await self._send_error(websocket, str(e))
                    
        except websockets.exceptions.ConnectionClosed:
            logger.info(f"GUI client disconnected: {client_addr}")
        except Exception as e:
            logger.error(f"Error with client {client_addr}: {e}")
        finally:
            self.clients.discard(websocket)
            
    async def _send_initial_state(self, websocket):
        """Send complete system state to new client"""
        messages = [
            {
                "type": "event",
                "data": {
                    "action": "system_status_update",
                    "payload": {
                        "agents": self.system_state["agents"],
                        "projects": self.system_state["projects"],
                        "token_usage": self.system_state["token_usage"],
                        "system_metrics": self.system_state["system_metrics"]
                    }
                }
            }
        ]
        
        for message in messages:
            await self._send_message(websocket, message)
            
    async def _handle_message(self, websocket, raw_message):
        """Handle incoming WebSocket message"""
        try:
            message = json.loads(raw_message)
            action = message.get("data", {}).get("action")
            payload = message.get("data", {}).get("payload", {})
            
            logger.info(f"Received action: {action}")
            
            if action == "get_system_status":
                await self._handle_system_status_request(websocket)
            elif action == "execute_workflow":
                await self._handle_workflow_execution(websocket, payload)
            elif action == "delegate_task":
                await self._handle_task_delegation(websocket, payload)
            elif action == "get_agent_details":
                await self._handle_agent_details_request(websocket, payload)
            elif action == "get_project_details":
                await self._handle_project_details_request(websocket, payload)
            else:
                await self._send_error(websocket, f"Unknown action: {action}")
                
        except json.JSONDecodeError as e:
            await self._send_error(websocket, f"Invalid JSON: {e}")
        except Exception as e:
            await self._send_error(websocket, f"Error handling message: {e}")
            
    async def _handle_system_status_request(self, websocket):
        """Handle system status request"""
        await self._send_message(websocket, {
            "type": "response",
            "data": {
                "action": "system_status_response",
                "payload": self.system_state
            }
        })
        
    async def _handle_workflow_execution(self, websocket, payload):
        """Handle workflow execution request"""
        workflow_name = payload.get("workflow")
        project_name = payload.get("project")
        context = payload.get("context", {})
        
        if not workflow_name or not project_name:
            await self._send_error(websocket, "Missing workflow or project name")
            return
            
        try:
            # Simulate workflow execution
            workflow_id = f"workflow_{int(time.time())}"
            
            # Create workflow execution record
            workflow_execution = {
                "id": workflow_id,
                "name": workflow_name,
                "project": project_name,
                "status": "running",
                "started_at": datetime.now().isoformat(),
                "steps": []
            }
            
            self.system_state["workflows"].append(workflow_execution)
            
            # Send workflow started response
            await self._send_message(websocket, {
                "type": "response",
                "data": {
                    "action": "workflow_started",
                    "payload": {
                        "workflow_id": workflow_id,
                        "status": "started"
                    }
                }
            })
            
            # Simulate workflow progress (in real implementation, this would integrate with actual workflow engine)
            asyncio.create_task(self._simulate_workflow_progress(workflow_id))
            
        except Exception as e:
            await self._send_error(websocket, f"Failed to start workflow: {e}")
            
    async def _handle_task_delegation(self, websocket, payload):
        """Handle task delegation request"""
        agent_name = payload.get("agent")
        task_data = payload.get("task", {})
        
        if not agent_name or not task_data:
            await self._send_error(websocket, "Missing agent or task data")
            return
            
        try:
            # Update agent status
            for agent in self.system_state["agents"]:
                if agent["name"] == agent_name:
                    agent["status"] = "executing"
                    agent["current_task"] = task_data.get("description", "Unknown task")
                    agent["last_activity"] = datetime.now().isoformat()
                    break
                    
            # Broadcast agent status update
            await self._broadcast_message({
                "type": "event",
                "data": {
                    "action": "agent_status_update",
                    "payload": {
                        "agent": agent_name,
                        "status": "executing",
                        "task": task_data.get("description"),
                        "progress": 0.0
                    }
                }
            })
            
            # Simulate task execution
            asyncio.create_task(self._simulate_task_execution(agent_name, task_data))
            
            await self._send_message(websocket, {
                "type": "response",
                "data": {
                    "action": "task_delegated",
                    "payload": {
                        "agent": agent_name,
                        "status": "accepted"
                    }
                }
            })
            
        except Exception as e:
            await self._send_error(websocket, f"Failed to delegate task: {e}")
            
    async def _handle_agent_details_request(self, websocket, payload):
        """Handle agent details request"""
        agent_name = payload.get("agent")
        
        agent = next((a for a in self.system_state["agents"] if a["name"] == agent_name), None)
        
        if agent:
            await self._send_message(websocket, {
                "type": "response",
                "data": {
                    "action": "agent_details_response",
                    "payload": agent
                }
            })
        else:
            await self._send_error(websocket, f"Agent not found: {agent_name}")
            
    async def _handle_project_details_request(self, websocket, payload):
        """Handle project details request"""
        project_name = payload.get("project")
        
        project = next((p for p in self.system_state["projects"] if p["name"] == project_name), None)
        
        if project:
            await self._send_message(websocket, {
                "type": "response",
                "data": {
                    "action": "project_details_response",
                    "payload": project
                }
            })
        else:
            await self._send_error(websocket, f"Project not found: {project_name}")
            
    async def _send_message(self, websocket, message):
        """Send message to specific client"""
        message_with_metadata = {
            **message,
            "id": f"msg_{int(time.time() * 1000)}",
            "timestamp": datetime.now().isoformat(),
            "source": "backend"
        }
        
        try:
            await websocket.send(json.dumps(message_with_metadata))
        except websockets.exceptions.ConnectionClosed:
            logger.warning("Attempted to send message to closed connection")
        except Exception as e:
            logger.error(f"Error sending message: {e}")
            
    async def _broadcast_message(self, message):
        """Broadcast message to all connected clients"""
        if not self.clients:
            return
            
        message_with_metadata = {
            **message,
            "id": f"msg_{int(time.time() * 1000)}",
            "timestamp": datetime.now().isoformat(),
            "source": "backend"
        }
        
        # Send to all clients
        disconnected_clients = set()
        
        for client in self.clients:
            try:
                await client.send(json.dumps(message_with_metadata))
            except websockets.exceptions.ConnectionClosed:
                disconnected_clients.add(client)
            except Exception as e:
                logger.error(f"Error broadcasting to client: {e}")
                disconnected_clients.add(client)
                
        # Clean up disconnected clients
        self.clients -= disconnected_clients
        
    async def _send_error(self, websocket, error_message):
        """Send error message to client"""
        await self._send_message(websocket, {
            "type": "response",
            "data": {
                "action": "error",
                "payload": {
                    "error": error_message
                }
            }
        })
        
    async def _background_updates(self):
        """Background task for periodic updates"""
        while self.running:
            try:
                await self._update_system_metrics()
                await self._update_token_usage()
                await self._check_agent_status()
                
                # Broadcast updates every 2 seconds
                await asyncio.sleep(2)
                
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Error in background updates: {e}")
                await asyncio.sleep(5)
                
    async def _update_system_metrics(self):
        """Update system performance metrics"""
        try:
            import psutil
            
            self.system_state["system_metrics"] = {
                "cpu_usage": psutil.cpu_percent(interval=None),
                "memory_usage": psutil.virtual_memory().percent,
                "active_agents": sum(1 for agent in self.system_state["agents"] if agent["status"] == "executing"),
                "last_updated": datetime.now().isoformat()
            }
            
            await self._broadcast_message({
                "type": "event",
                "data": {
                    "action": "system_metrics_update",
                    "payload": self.system_state["system_metrics"]
                }
            })
            
        except ImportError:
            # psutil not available, use mock data
            pass
        except Exception as e:
            logger.error(f"Error updating system metrics: {e}")
            
    async def _update_token_usage(self):
        """Update token usage statistics"""
        # In real implementation, this would pull from Context Engineering MCP
        # For now, simulate token usage
        import random
        
        self.system_state["token_usage"]["session_tokens"] += random.randint(1, 50)
        self.system_state["token_usage"]["total_tokens"] += random.randint(1, 50)
        
        await self._broadcast_message({
            "type": "event",
            "data": {
                "action": "token_usage_update",
                "payload": self.system_state["token_usage"]
            }
        })
        
    async def _check_agent_status(self):
        """Check and update agent statuses"""
        # Simulate agent status changes
        import random
        
        for agent in self.system_state["agents"]:
            if agent["status"] == "executing" and random.random() < 0.1:
                # Occasionally complete tasks
                agent["status"] = "idle"
                agent["current_task"] = None
                agent["progress"] = 0.0
                
                await self._broadcast_message({
                    "type": "event",
                    "data": {
                        "action": "agent_status_update",
                        "payload": {
                            "agent": agent["name"],
                            "status": "idle",
                            "task": None,
                            "progress": 0.0
                        }
                    }
                })
                
    async def _simulate_workflow_progress(self, workflow_id):
        """Simulate workflow execution progress"""
        steps = ["initialization", "analysis", "execution", "validation", "completion"]
        
        workflow = next((w for w in self.system_state["workflows"] if w["id"] == workflow_id), None)
        if not workflow:
            return
            
        for i, step in enumerate(steps):
            await asyncio.sleep(2)  # Simulate step duration
            
            workflow["steps"].append({
                "name": step,
                "status": "completed",
                "completed_at": datetime.now().isoformat()
            })
            
            progress = (i + 1) / len(steps)
            
            await self._broadcast_message({
                "type": "event",
                "data": {
                    "action": "workflow_update",
                    "payload": {
                        "workflow_id": workflow_id,
                        "status": "running" if progress < 1.0 else "completed",
                        "progress": progress,
                        "current_step": step
                    }
                }
            })
            
        workflow["status"] = "completed"
        workflow["completed_at"] = datetime.now().isoformat()
        
    async def _simulate_task_execution(self, agent_name, task_data):
        """Simulate agent task execution"""
        duration = 5  # seconds
        
        for i in range(duration):
            await asyncio.sleep(1)
            progress = (i + 1) / duration
            
            await self._broadcast_message({
                "type": "event",
                "data": {
                    "action": "agent_status_update",
                    "payload": {
                        "agent": agent_name,
                        "status": "executing",
                        "task": task_data.get("description"),
                        "progress": progress
                    }
                }
            })
            
        # Mark agent as idle
        for agent in self.system_state["agents"]:
            if agent["name"] == agent_name:
                agent["status"] = "idle"
                agent["current_task"] = None
                agent["progress"] = 0.0
                break
                
        await self._broadcast_message({
            "type": "event",
            "data": {
                "action": "agent_status_update",
                "payload": {
                    "agent": agent_name,
                    "status": "idle",
                    "task": None,
                    "progress": 0.0
                }
            }
        })
        
    async def _initialize_integrations(self):
        """Initialize integrations with existing workflow-hub system"""
        try:
            # Initialize agent bridge if available
            # self.agent_bridge = AgentMCPBridge()
            # await self.agent_bridge.initialize()
            
            # Initialize delegation matrix
            # self.delegation_matrix = TaskDelegationMatrix()
            
            logger.info("System integrations initialized")
            
        except Exception as e:
            logger.warning(f"Could not initialize full integrations: {e}")
            logger.info("Running in standalone mode with simulated data")
            
    def _get_default_agents(self):
        """Get default agent configuration"""
        return [
            {
                "name": "ARQ",
                "specialization": ["architecture", "system_design", "scalability", "cloud"],
                "status": "idle",
                "current_task": None,
                "progress": 0.0,
                "last_activity": datetime.now().isoformat(),
                "expertise_level": 0.95,
                "current_load": 0,
                "max_parallel_tasks": 3
            },
            {
                "name": "ORC",
                "specialization": ["orchestration", "coordination", "workflow", "management"],
                "status": "idle",
                "current_task": None,
                "progress": 0.0,
                "last_activity": datetime.now().isoformat(),
                "expertise_level": 0.98,
                "current_load": 0,
                "max_parallel_tasks": 5
            },
            {
                "name": "ZEN",
                "specialization": ["code_quality", "refactoring", "algorithms", "optimization"],
                "status": "idle",
                "current_task": None,
                "progress": 0.0,
                "last_activity": datetime.now().isoformat(),
                "expertise_level": 0.93,
                "current_load": 0,
                "max_parallel_tasks": 3
            },
            {
                "name": "VEX",
                "specialization": ["ui_ux", "design", "user_experience", "creativity"],
                "status": "idle",
                "current_task": None,
                "progress": 0.0,
                "last_activity": datetime.now().isoformat(),
                "expertise_level": 0.92,
                "current_load": 0,
                "max_parallel_tasks": 2
            },
            {
                "name": "SAGE",
                "specialization": ["strategy", "market_analysis", "intelligence", "forecasting"],
                "status": "idle",
                "current_task": None,
                "progress": 0.0,
                "last_activity": datetime.now().isoformat(),
                "expertise_level": 0.94,
                "current_load": 0,
                "max_parallel_tasks": 3
            },
            {
                "name": "NOVA",
                "specialization": ["innovation", "breakthrough", "emerging_tech", "r_and_d"],
                "status": "idle",
                "current_task": None,
                "progress": 0.0,
                "last_activity": datetime.now().isoformat(),
                "expertise_level": 0.91,
                "current_load": 0,
                "max_parallel_tasks": 2
            },
            {
                "name": "ECHO",
                "specialization": ["community", "content", "culture", "communication"],
                "status": "idle",
                "current_task": None,
                "progress": 0.0,
                "last_activity": datetime.now().isoformat(),
                "expertise_level": 0.90,
                "current_load": 0,
                "max_parallel_tasks": 3
            }
        ]
        
    def _get_default_projects(self):
        """Get default project configuration"""
        return [
            {
                "name": "exxede.diy",
                "type": "nextjs",
                "status": "production",
                "priority": 5,
                "completion": 0.85,
                "agent_team": ["ARQ", "ZEN", "ORC"],
                "last_modified": datetime.now().isoformat(),
                "health": "good"
            },
            {
                "name": "ReppingDR",
                "type": "business",
                "status": "production",
                "priority": 5,
                "completion": 0.85,
                "agent_team": ["SAGE", "ECHO", "VEX", "ORC"],
                "last_modified": datetime.now().isoformat(),
                "health": "good"
            },
            {
                "name": "Context-Engineering",
                "type": "ai_ml",
                "status": "production",
                "priority": 4,
                "completion": 0.90,
                "agent_team": ["NOVA", "ARQ", "ZEN"],
                "last_modified": datetime.now().isoformat(),
                "health": "excellent"
            },
            {
                "name": "CLAI",
                "type": "ai_ml",
                "status": "production",
                "priority": 4,
                "completion": 0.90,
                "agent_team": ["ZEN", "ARQ", "NOVA"],
                "last_modified": datetime.now().isoformat(),
                "health": "good"
            },
            {
                "name": "Ocean Paradise",
                "type": "real_estate",
                "status": "planning",
                "priority": 3,
                "completion": 0.25,
                "agent_team": ["SAGE", "VEX", "ORC"],
                "last_modified": datetime.now().isoformat(),
                "health": "planning"
            }
        ]

async def main():
    """Main function to start the server"""
    server = GUIWebSocketServer()
    
    try:
        await server.start_server()
    except KeyboardInterrupt:
        logger.info("Server interrupted by user")
    except Exception as e:
        logger.error(f"Server error: {e}")
    finally:
        await server.stop_server()

if __name__ == "__main__":
    asyncio.run(main())