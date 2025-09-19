# 🎯 CNCF Pune K8sGPT Demo Guide

## Quick Start for Presenters

### Pre-Demo Setup (5 minutes)
```bash
# Validate everything is working
./scripts/validate-setup.sh

# Open required terminals
# Terminal 1: Main demo commands
# Terminal 2: Watch pods (optional)
watch kubectl get pods -n demo
```

### Demo Flow (20-30 minutes)

#### 1. Introduction (2 minutes)
- Show architecture diagram
- Explain K8sGPT + Ollama integration
- Mention local LLM models (no external API needed)

#### 2. Environment Overview (3 minutes)
```bash
# Show cluster status
kubectl get nodes
kubectl get namespaces

# Show Ollama models
ollama list

# Show K8sGPT configuration
k8sgpt auth list
```

#### 3. Working Demo App (2 minutes)
```bash
# Show healthy application
kubectl get pods,svc -n demo

# Access demo app
open http://cncf.vg.local
```

#### 4. Scenario Demonstrations (15 minutes)

##### Scenario 1: ImagePullBackOff
```bash
# Deploy broken scenario
./scenarios/run-scenario.sh 1

# Show traditional troubleshooting
kubectl get pods -n demo
kubectl describe pod <pod-name> -n demo

# Show K8sGPT magic
k8sgpt analyze --namespace demo --filter Pod --explain

# Fix the issue
./scenarios/run-scenario.sh 1 fix
```

##### Scenario 2: Service Selector Mismatch
```bash
# Deploy service mismatch scenario
./scenarios/run-scenario.sh 2

# Show the issue
kubectl get pods,svc -n demo
kubectl get endpoints -n demo

# Let K8sGPT analyze
k8sgpt analyze --namespace demo --filter Service --explain

# Fix the issue
./scenarios/run-scenario.sh 2 fix
```

##### Scenario 3: Resource Constraints
```bash
# Deploy resource issue scenario
./scenarios/run-scenario.sh 3

# Show resource problems
kubectl get pods -n demo
kubectl top pods -n demo

# Analyze with K8sGPT
k8sgpt analyze --namespace demo --explain

# Fix the issue
./scenarios/run-scenario.sh 3 fix
```

#### 5. Model Comparison (5 minutes)
```bash
# Switch to different model
~/.k8sgpt/switch-model.sh llama2:13b

# Run same analysis with different model
k8sgpt analyze --namespace demo --explain

# Compare results and speed
```

## Demo Commands Cheat Sheet

### Quick Setup Validation
```bash
./scripts/validate-setup.sh
```

### Scenario Management
```bash
# Deploy scenarios
./scenarios/run-scenario.sh 1    # ImagePullBackOff
./scenarios/run-scenario.sh 2    # Service mismatch
./scenarios/run-scenario.sh 3    # Resource limits

# Fix scenarios
./scenarios/run-scenario.sh 1 fix
./scenarios/run-scenario.sh 2 fix
./scenarios/run-scenario.sh 3 fix

# Clean up scenarios
./scenarios/run-scenario.sh 1 clean
```

### K8sGPT Commands
```bash
# Basic analysis
k8sgpt analyze

# Namespace-specific analysis
k8sgpt analyze --namespace demo

# Filtered analysis with explanation
k8sgpt analyze --namespace demo --filter Pod --explain
k8sgpt analyze --namespace demo --filter Service --explain
k8sgpt analyze --namespace demo --filter Deployment --explain

# Clear cache for fresh analysis
k8sgpt analyze --no-cache
```

### Model Management
```bash
# List available models
ollama list

# Switch K8sGPT model
~/.k8sgpt/switch-model.sh mistral:7b
~/.k8sgpt/switch-model.sh llama2:13b
~/.k8sgpt/switch-model.sh orca-mini:latest

# Check current configuration
k8sgpt auth list
```

## Troubleshooting During Demo

### If Ollama is not responding
```bash
# Check Ollama status
curl http://localhost:11434/api/tags

# Restart if needed
pkill ollama
ollama serve &
```

### If scenario deployment fails
```bash
# Verify scenario files exist
ls -la scenarios/scenario-*/k8s/

# Test scenario script from project root
./scenarios/run-scenario.sh

# Run with kubectl directly if needed
kubectl apply -f scenarios/scenario-1/k8s/error_1.yaml
```

### If K8sGPT analysis is slow
```bash
# Switch to faster model
~/.k8sgpt/switch-model.sh orca-mini:latest

# Use analysis without explanation for speed
k8sgpt analyze --namespace demo --no-cache
```

### If demo app is not accessible
```bash
# Check ingress and service
kubectl get ingress,svc -n demo

# Check /etc/hosts entry
grep cncf.vg.local /etc/hosts

# Port forward as backup
kubectl port-forward svc/cncf-pune-demo 8080:80 -n demo
# Then access: http://localhost:8080
```

## Backup Slides

Have these ready in case of technical issues:
1. Architecture diagram
2. K8sGPT benefits overview
3. Local LLM advantages
4. Use case examples
5. Community resources

## Time Management

- 45-min session: Focus on 2 scenarios + Q&A
- 30-min session: Focus on 1 scenario + overview
- 60-min session: All 3 scenarios + deep dive

## Q&A Preparation

Common questions:
1. **Performance**: Local models vs cloud APIs
2. **Privacy**: Benefits of local LLM processing
3. **Cost**: No API costs, just compute resources
4. **Integration**: How to integrate in CI/CD
5. **Models**: Which model for production use
6. **Scaling**: Running in production clusters
