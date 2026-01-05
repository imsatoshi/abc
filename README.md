# LLM Agents & Context Engineering

## Overview
Comprehensive resource index about **Autonomous Agents / Context Engineering** with personal commentary, focused mainly on engineering aspects.

## Core Concepts

### 1. Autonomous Agents vs Workflow Agents
- **Autonomous agents**: Operate independently with decision-making capabilities
- **Workflow agents**: Follow predefined sequences and patterns

### 2. Context Engineering
- Managing conversation history and information flow
- Context compression, memory management, offloading techniques

## Key Technical Patterns

### Agent Skills Paradigm
- Most elegant way to inject vertical capabilities
- Replaces MCP (Model Context Protocol) for capability injection
- Recommended by practitioners

### Tool Use Patterns
- **Tool Search Tool**: Dynamic tool discovery
- **Programmatic Tool Calling**: Code-based tool invocation
- **Tool Use Examples**: Learning from demonstrations

### SubAgent Pattern
- "Agent as Tool" concept
- Used in Claude Deep Research
- Enables complex task decomposition

### Context Management
- **Context Compression**: Reducing token usage
- **Context Offload**: Moving data out of main context
- **Context Reduce**: Filtering relevant information
- **Context Isolate**: Separating concerns

## Major Frameworks

### Anthropic's Stack
- Claude Deep Research (multi-agent system)
- Claude Agent SDK
- Claude Code (autonomous coding agent)

### Open Source
- **Kimi CLI Agent**: Elegant CLI implementation
- **LangChain DeepAgents**: Middleware-based architecture
- **rLLM SDK**: Training agentic programs

## Performance Metrics
- Agent task completion ability **doubles every 7 months**
- Rapid evolution in architecture and models

## Best Practices
1. Design tools with optimized parameters and error handling
2. Use Skills over MCP for capability injection
3. Implement proper context management
4. Consider sandboxing for security
5. Focus on long-running agent architectures

## Current Trends
- Shift from pipeline-based to model-native agentic AI
- Integration of context engineering with agent capabilities
- Emphasis on practical engineering over academic research

## Key Resources

### Must-Read Articles
- Anthropic's multi-agent research system (Claude Deep Research)
- Context engineering fundamentals
- Advanced tool use patterns
- Agent Skills framework
- Tool design best practices

### Open Source Projects
- Kimi CLI Agent
- LangChain DeepAgents
- rLLM SDK

This represents the current state-of-the-art in LLM agent development as of early 2025.