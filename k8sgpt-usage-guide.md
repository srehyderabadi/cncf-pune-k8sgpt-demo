# K8sGPT Usage Guide

## Quick Commands

```bash
# Basic analysis
k8sgpt analyze

# Analyze specific namespace
k8sgpt analyze --namespace demo

# Analyze with explanation (uses LLM)
k8sgpt analyze --explain

# Filter specific resource types
k8sgpt analyze --filter Pod
k8sgpt analyze --filter Deployment,Service

# Analyze and explain specific issues
k8sgpt analyze --namespace demo --filter Pod --explain
```

## Authentication Management

```bash
# List current authentication
k8sgpt auth list

# Switch to different model
~/.k8sgpt/switch-model.sh llama2:13b

# Remove authentication
k8sgpt auth remove --backends ollama

# Add authentication
k8sgpt auth add --backend ollama --baseurl http://localhost:11434 --model mistral:7b
```

## Common Use Cases

### 1. Pod Issues
```bash
k8sgpt analyze --filter Pod --explain
```

### 2. Service Problems
```bash
k8sgpt analyze --filter Service --explain
```

### 3. Deployment Analysis
```bash
k8sgpt analyze --filter Deployment --explain
```

### 4. Full Cluster Scan
```bash
k8sgpt analyze --explain
```

## Available Models

- **mistral:7b** - Fast, efficient (recommended for demos)
- **llama2:13b** - More comprehensive analysis
- **orca-mini:latest** - Lightweight option

## Configuration Files

- Config Directory: `~/.k8sgpt`
- Model Switcher: `~/.k8sgpt/switch-model.sh`
- Ollama Service: `http://localhost:11434`

## Troubleshooting

### K8sGPT not finding issues
```bash
# Clear cache and re-analyze
k8sgpt analyze --no-cache
```

### Model switching issues
```bash
# Check available models
curl -s http://localhost:11434/api/tags | jq '.models[].name'

# Reset authentication
k8sgpt auth remove --backends ollama
k8sgpt auth add --backend ollama --baseurl http://localhost:11434 --model mistral:7b
```

### Slow analysis
```bash
# Use faster model
~/.k8sgpt/switch-model.sh orca-mini:latest

# Analyze without explanation for speed
k8sgpt analyze --namespace demo
```
