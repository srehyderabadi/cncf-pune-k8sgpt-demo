#!/bin/bash

# 🎮 Complete Demo Setup Script
# Author: CNCF Pune Demo Project
# Description: Sets up the complete demo environment and deploys demo application

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_demo() { echo -e "${PURPLE}[DEMO]${NC} $1"; }

# Configuration
CLUSTER_NAME="cncf-pune-k3d-demo"
DEMO_NAMESPACE="demo"
DEMO_APP_NAME="cncf-pune-demo"

print_banner() {
    echo "======================================================"
    echo "🎮 Complete Demo Environment Setup"
    echo "======================================================"
    echo "This script will:"
    echo "  🚀 Run all installation scripts in sequence"
    echo "  🏗️  Build and deploy demo application"
    echo "  💥 Set up failure scenarios"
    echo "  ✅ Validate complete environment"
    echo "  📋 Generate demo instructions"
    echo "======================================================"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS. Detected: $OSTYPE"
        exit 1
    fi
    
    # Check if in correct directory
    if [[ ! -f "scripts/install-k3d.sh" ]]; then
        log_error "Please run this script from the project root directory"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

run_installation_sequence() {
    log_info "Running complete installation sequence..."
    
    # Make all scripts executable
    chmod +x scripts/*.sh
    
    # Run K3D installation
    log_info "Step 1/3: Setting up K3D cluster..."
    if ./scripts/install-k3d.sh; then
        log_success "K3D setup completed"
    else
        log_error "K3D setup failed"
        exit 1
    fi
    
    # Run Ollama installation
    log_info "Step 2/3: Setting up Ollama and LLM models..."
    if ./scripts/install-ollama.sh; then
        log_success "Ollama setup completed"
    else
        log_error "Ollama setup failed"
        exit 1
    fi
    
    # Run K8sGPT installation
    log_info "Step 3/3: Setting up K8sGPT..."
    if ./scripts/install-k8sgpt.sh; then
        log_success "K8sGPT setup completed"
    else
        log_error "K8sGPT setup failed"
        exit 1
    fi
}

build_demo_application() {
    log_info "Building demo application..."
    
    cd demo-app
    
    # Build Docker image
    log_info "Building Docker image: ${DEMO_APP_NAME}:latest"
    docker build -t "${DEMO_APP_NAME}:latest" .
    
    # Import image to K3D cluster
    log_info "Importing image to K3D cluster..."
    k3d image import "${DEMO_APP_NAME}:latest" --cluster "$CLUSTER_NAME"
    
    log_success "Demo application built and imported"
    
    cd ..
}

deploy_demo_application() {
    log_info "Deploying demo application..."
    
    # Ensure demo namespace exists
    kubectl create namespace "$DEMO_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy application
    kubectl apply -f demo-app/k8s/deployment.yaml
    
    # Wait for deployment to be ready
    log_info "Waiting for demo application to be ready..."
    kubectl wait --for=condition=Available deployment/"$DEMO_APP_NAME" -n "$DEMO_NAMESPACE" --timeout=120s
    
    # Check deployment status
    kubectl get pods,svc,ingress -n "$DEMO_NAMESPACE"
    
    log_success "Demo application deployed successfully"
}

setup_host_entry() {
    log_info "Setting up local host entry for demo app..."
    
    HOST_ENTRY="127.0.0.1 cncf.vg.local"
    
    if ! grep -q "cncf.vg.local" /etc/hosts; then
        log_info "Adding host entry to /etc/hosts (requires sudo)..."
        echo "$HOST_ENTRY" | sudo tee -a /etc/hosts > /dev/null
        log_success "Host entry added: $HOST_ENTRY"
    else
        log_info "Host entry already exists"
    fi
}

validate_demo_scenarios() {
    log_info "Validating demo scenarios..."
    
    # Ensure scenarios directory structure
    if [[ ! -d "scenarios" ]]; then
        log_error "Scenarios directory not found"
        exit 1
    fi
    
    # Check if scenario runner script exists and is executable
    if [[ -f "scenarios/run-scenario.sh" ]]; then
        chmod +x scenarios/run-scenario.sh
        log_success "Scenario runner script found and made executable"
    else
        log_warning "Scenario runner script not found. Scenarios may not work properly."
    fi
    
    # Check scenario files
    for i in {1..3}; do
        if [[ -f "scenarios/scenario-$i/k8s/error_$i.yaml" && -f "scenarios/scenario-$i/k8s/fix_$i.yaml" ]]; then
            log_success "Scenario $i files found"
        else
            log_warning "Scenario $i files missing"
        fi
    done
}

test_complete_workflow() {
    log_info "Testing complete workflow..."
    
    # Test K8sGPT basic functionality
    log_info "Testing K8sGPT analysis..."
    k8sgpt analyze --namespace "$DEMO_NAMESPACE" --no-cache
    
    # Test demo application access
    log_info "Testing demo application access..."
    if curl -s http://cncf.vg.local > /dev/null; then
        log_success "Demo application is accessible at http://cncf.vg.local"
    else
        log_warning "Demo application might not be fully ready yet"
    fi
    
    # Test scenario files exist and script is executable
    log_info "Testing scenario setup..."
    if [[ -x "scenarios/run-scenario.sh" ]]; then
        log_success "Scenario runner script is executable"
        
        # Test that scenario files can be found
        if ./scenarios/run-scenario.sh 2>&1 | grep -q "Usage:"; then
            log_success "Scenario runner script is functional"
        else
            log_warning "Scenario runner script may have issues"
        fi
    else
        log_warning "Scenario runner script not found or not executable"
    fi
    
    log_success "Complete workflow test passed"
}

create_demo_guide() {
    log_info "Creating comprehensive demo guide..."
    
    cat > "DEMO_GUIDE.md" << EOF
# 🎯 CNCF Pune K8sGPT Demo Guide

## Quick Start for Presenters

### Pre-Demo Setup (5 minutes)
\`\`\`bash
# Validate everything is working
./scripts/validate-setup.sh

# Open required terminals
# Terminal 1: Main demo commands
# Terminal 2: Watch pods (optional)
watch kubectl get pods -n demo
\`\`\`

### Demo Flow (20-30 minutes)

#### 1. Introduction (2 minutes)
- Show architecture diagram
- Explain K8sGPT + Ollama integration
- Mention local LLM models (no external API needed)

#### 2. Environment Overview (3 minutes)
\`\`\`bash
# Show cluster status
kubectl get nodes
kubectl get namespaces

# Show Ollama models
ollama list

# Show K8sGPT configuration
k8sgpt auth list
\`\`\`

#### 3. Working Demo App (2 minutes)
\`\`\`bash
# Show healthy application
kubectl get pods,svc -n demo

# Access demo app
open http://cncf.vg.local
\`\`\`

#### 4. Scenario Demonstrations (15 minutes)

##### Scenario 1: ImagePullBackOff
\`\`\`bash
# Deploy broken scenario
./scenarios/run-scenario.sh 1

# Show traditional troubleshooting
kubectl get pods -n demo
kubectl describe pod <pod-name> -n demo

# Show K8sGPT magic
k8sgpt analyze --namespace demo --filter Pod --explain

# Fix the issue
./scenarios/run-scenario.sh 1 fix
\`\`\`

##### Scenario 2: Service Selector Mismatch
\`\`\`bash
# Deploy service mismatch scenario
./scenarios/run-scenario.sh 2

# Show the issue
kubectl get pods,svc -n demo
kubectl get endpoints -n demo

# Let K8sGPT analyze
k8sgpt analyze --namespace demo --filter Service --explain

# Fix the issue
./scenarios/run-scenario.sh 2 fix
\`\`\`

##### Scenario 3: Resource Constraints
\`\`\`bash
# Deploy resource issue scenario
./scenarios/run-scenario.sh 3

# Show resource problems
kubectl get pods -n demo
kubectl top pods -n demo

# Analyze with K8sGPT
k8sgpt analyze --namespace demo --explain

# Fix the issue
./scenarios/run-scenario.sh 3 fix
\`\`\`

#### 5. Model Comparison (5 minutes)
\`\`\`bash
# Switch to different model
~/.k8sgpt/switch-model.sh llama2:13b

# Run same analysis with different model
k8sgpt analyze --namespace demo --explain

# Compare results and speed
\`\`\`

## Demo Commands Cheat Sheet

### Quick Setup Validation
\`\`\`bash
./scripts/validate-setup.sh
\`\`\`

### Scenario Management
\`\`\`bash
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
\`\`\`

### K8sGPT Commands
\`\`\`bash
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
\`\`\`

### Model Management
\`\`\`bash
# List available models
ollama list

# Switch K8sGPT model
~/.k8sgpt/switch-model.sh mistral:7b
~/.k8sgpt/switch-model.sh llama2:13b
~/.k8sgpt/switch-model.sh orca-mini:latest

# Check current configuration
k8sgpt auth list
\`\`\`

## Troubleshooting During Demo

### If Ollama is not responding
\`\`\`bash
# Check Ollama status
curl http://localhost:11434/api/tags

# Restart if needed
pkill ollama
ollama serve &
\`\`\`

### If scenario deployment fails
\`\`\`bash
# Verify scenario files exist
ls -la scenarios/scenario-*/k8s/

# Test scenario script from project root
./scenarios/run-scenario.sh

# Run with kubectl directly if needed
kubectl apply -f scenarios/scenario-1/k8s/error_1.yaml
\`\`\`

### If K8sGPT analysis is slow
\`\`\`bash
# Switch to faster model
~/.k8sgpt/switch-model.sh orca-mini:latest

# Use analysis without explanation for speed
k8sgpt analyze --namespace demo --no-cache
\`\`\`

### If demo app is not accessible
\`\`\`bash
# Check ingress and service
kubectl get ingress,svc -n demo

# Check /etc/hosts entry
grep cncf.vg.local /etc/hosts

# Port forward as backup
kubectl port-forward svc/cncf-pune-demo 8080:80 -n demo
# Then access: http://localhost:8080
\`\`\`

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
EOF
    
    log_success "Demo guide created: DEMO_GUIDE.md"
}

create_quick_reference() {
    log_info "Creating quick reference card..."
    
    cat > "QUICK_REFERENCE.md" << EOF
# 🚀 Quick Reference Card

## One-Command Setup
\`\`\`bash
./scripts/setup-demo.sh
\`\`\`

## Demo Flow
1. **Setup**: \`./scripts/validate-setup.sh\`
2. **Scenario**: \`./scenarios/run-scenario.sh 1\`
3. **Analyze**: \`k8sgpt analyze --namespace demo --explain\`
4. **Fix**: \`./scenarios/run-scenario.sh 1 fix\`

## Key URLs
- **Demo App**: http://cncf.vg.local
- **Ollama API**: http://localhost:11434
- **Cluster**: https://127.0.0.1:6443

## Emergency Commands
\`\`\`bash
# Restart everything
./scripts/setup-demo.sh

# Check status
./scripts/validate-setup.sh

# Clean slate
k3d cluster delete cncf-pune-k3d-demo
./scripts/install-k3d.sh
\`\`\`
EOF
    
    log_success "Quick reference created: QUICK_REFERENCE.md"
}

main() {
    print_banner
    
    check_prerequisites
    
    # Run in sequence with option to skip already completed steps
    if [[ "${1:-}" != "--skip-install" ]]; then
        run_installation_sequence
    else
        log_info "Skipping installation sequence (--skip-install flag used)"
    fi
    
    build_demo_application
    deploy_demo_application
    setup_host_entry
    validate_demo_scenarios
    test_complete_workflow
    create_demo_guide
    create_quick_reference
    
    echo ""
    echo "🎉 Complete Demo Setup Finished!"
    echo "======================================="
    echo "🌐 Demo App: http://cncf.vg.local"
    echo "🦙 Ollama API: http://localhost:11434"
    echo "☸️  Cluster: k3d-${CLUSTER_NAME}"
    echo "📋 Demo Guide: DEMO_GUIDE.md"
    echo "🚀 Quick Ref: QUICK_REFERENCE.md"
    echo "======================================="
    
    log_success "Demo environment is ready for presentation!"
    log_demo "Try running: ./scenarios/run-scenario.sh 1"
    log_demo "Then run: k8sgpt analyze --namespace demo --explain"
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi