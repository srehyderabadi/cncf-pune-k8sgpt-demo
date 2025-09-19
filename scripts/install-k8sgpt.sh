#!/bin/bash

# 🔍 K8sGPT Installation & Configuration Script
# Author: CNCF Pune Demo Project
# Description: Installs K8sGPT and configures it with Ollama backend

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration
OLLAMA_URL="http://localhost:11434"
DEFAULT_MODEL="mistral:7b"
K8SGPT_CONFIG_DIR="$HOME/.k8sgpt"

print_banner() {
    echo "======================================================"
    echo "🔍 K8sGPT Installation & Configuration"
    echo "======================================================"
    echo "This script will:"
    echo "  🔍 Check for existing K8sGPT installation"
    echo "  📥 Install K8sGPT via Homebrew (if needed)"
    echo "  🔧 Configure K8sGPT with Ollama backend"
    echo "  🧪 Test K8sGPT functionality"
    echo "  ✅ Validate integration with Kubernetes cluster"
    echo "======================================================"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS. Detected: $OSTYPE"
        exit 1
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please run install-k3d.sh first."
        exit 1
    fi
    
    # Check if Kubernetes cluster is accessible
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Kubernetes cluster is not accessible. Please run install-k3d.sh first."
        exit 1
    fi
    log_success "Kubernetes cluster is accessible"
    
    # Check if Ollama is running
    if ! curl -s "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
        log_error "Ollama is not running at $OLLAMA_URL. Please run install-ollama.sh first."
        exit 1
    fi
    log_success "Ollama service is running and accessible"
    
    # Check if required models are available
    models_json=$(curl -s "$OLLAMA_URL/api/tags")
    if ! echo "$models_json" | jq -r '.models[].name' | grep -q "$DEFAULT_MODEL"; then
        log_error "Default model $DEFAULT_MODEL not found in Ollama. Available models:"
        echo "$models_json" | jq -r '.models[].name'
        exit 1
    fi
    log_success "Required Ollama models are available"
}

install_k8sgpt() {
    log_info "Checking K8sGPT installation..."
    
    # Check if K8sGPT is already available
    if command -v k8sgpt &> /dev/null; then
        CURRENT_VERSION=$(k8sgpt version 2>/dev/null | head -n1 || echo "unknown version")
        log_success "K8sGPT is already installed: $CURRENT_VERSION"
        log_info "Skipping installation, proceeding with configuration..."
        return 0
    fi
    
    log_info "K8sGPT not found, installing via Homebrew..."
    
    # Check if Homebrew is available
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew is not installed. Please install Homebrew first."
        log_info "Install from: https://brew.sh/"
        exit 1
    fi
    
    # Update Homebrew to get latest formula
    log_info "Updating Homebrew..."
    brew update
    
    # Install K8sGPT via Homebrew
    log_info "Installing K8sGPT..."
    if brew list k8sgpt &> /dev/null; then
        log_info "K8sGPT already installed via Homebrew, upgrading..."
        brew upgrade k8sgpt
    else
        brew install k8sgpt
    fi
    
    # Verify installation
    if ! command -v k8sgpt &> /dev/null; then
        log_error "K8sGPT installation failed. Binary not found in PATH."
        log_error "Try running: brew doctor"
        exit 1
    fi
    
    # Get and display version
    INSTALLED_VERSION=$(k8sgpt version | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    log_success "K8sGPT ${INSTALLED_VERSION} installed successfully via Homebrew"
    log_info "Version: $(k8sgpt version | head -n1)"
}

configure_k8sgpt() {
    log_info "Configuring K8sGPT with Ollama backend..."
    
    # Create K8sGPT config directory
    mkdir -p "$K8SGPT_CONFIG_DIR"
    
    # Remove any existing Ollama backend configuration
    k8sgpt auth remove --backends ollama &> /dev/null || true
    
    # Add Ollama backend with default model
    log_info "Adding Ollama backend with model: $DEFAULT_MODEL"
    k8sgpt auth add --backend ollama --baseurl "$OLLAMA_URL" --model "$DEFAULT_MODEL"
    
    # Set Ollama as default provider
    k8sgpt auth default --provider ollama
    
    log_success "K8sGPT configured with Ollama backend"
    
    # Display authentication status
    log_info "Current authentication configuration:"
    k8sgpt auth list
}

configure_additional_models() {
    log_info "Configuring additional models..."
    
    # Get list of available models from Ollama
    models_json=$(curl -s "$OLLAMA_URL/api/tags")
    available_models=$(echo "$models_json" | jq -r '.models[].name' | grep -E "(mistral|llama|orca)")
    
    log_info "Available models for configuration:"
    echo "$available_models"
    
    # Create configuration script for easy model switching
    cat > "$K8SGPT_CONFIG_DIR/switch-model.sh" << 'EOF'
#!/bin/bash
# K8sGPT Model Switcher Script

OLLAMA_URL="http://localhost:11434"

usage() {
    echo "Usage: $0 [model-name]"
    echo ""
    echo "Available models:"
    curl -s "$OLLAMA_URL/api/tags" | jq -r '.models[].name' | sed 's/^/  - /'
    echo ""
    echo "Examples:"
    echo "  $0 mistral:7b"
    echo "  $0 llama2:13b"
    echo "  $0 orca-mini:latest"
}

if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

MODEL="$1"

echo "Switching K8sGPT to model: $MODEL"

# Remove existing configuration
k8sgpt auth remove --backends ollama 2>/dev/null || true

# Add new configuration
k8sgpt auth add --backend ollama --baseurl "$OLLAMA_URL" --model "$MODEL"
k8sgpt auth default --provider ollama

echo "Successfully switched to model: $MODEL"
echo "Current configuration:"
k8sgpt auth list
EOF
    
    chmod +x "$K8SGPT_CONFIG_DIR/switch-model.sh"
    log_success "Model switcher script created at: $K8SGPT_CONFIG_DIR/switch-model.sh"
}

test_k8sgpt_functionality() {
    log_info "Testing K8sGPT functionality..."
    
    # Test basic K8sGPT commands
    log_info "Testing K8sGPT version command..."
    k8sgpt version
    
    log_info "Testing K8sGPT auth status..."
    k8sgpt auth list
    
    # Create a test deployment with an obvious issue for analysis
    log_info "Creating test deployment with intentional issue..."
    
    cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: k8sgpt-test
  namespace: demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: k8sgpt-test
  template:
    metadata:
      labels:
        app: k8sgpt-test
    spec:
      containers:
      - name: test-container
        image: nonexistent-image:latest
        imagePullPolicy: Always
EOF
    
    # Wait a moment for the issue to manifest
    sleep 10
    
    # Test K8sGPT analysis
    log_info "Running K8sGPT analysis on demo namespace..."
    
    if k8sgpt analyze --namespace demo --no-cache; then
        log_success "K8sGPT analysis completed successfully"
    else
        log_warning "K8sGPT analysis completed with warnings (this is normal for test scenarios)"
    fi
    
    # Test with explanation
    log_info "Testing K8sGPT with explanation..."
    
    if timeout 60 k8sgpt analyze --namespace demo --explain --no-cache; then
        log_success "K8sGPT explanation test completed"
    else
        log_warning "K8sGPT explanation test timed out (this can happen with slow models)"
    fi
    
    # Clean up test deployment
    kubectl delete deployment k8sgpt-test -n demo --ignore-not-found=true
    
    log_success "K8sGPT functionality test completed"
}

create_usage_guide() {
    log_info "Creating K8sGPT usage guide..."
    
    cat > "k8sgpt-usage-guide.md" << EOF
# K8sGPT Usage Guide

## Quick Commands

\`\`\`bash
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
\`\`\`

## Authentication Management

\`\`\`bash
# List current authentication
k8sgpt auth list

# Switch to different model
~/.k8sgpt/switch-model.sh llama2:13b

# Remove authentication
k8sgpt auth remove --backends ollama

# Add authentication
k8sgpt auth add --backend ollama --baseurl http://localhost:11434 --model mistral:7b
\`\`\`

## Common Use Cases

### 1. Pod Issues
\`\`\`bash
k8sgpt analyze --filter Pod --explain
\`\`\`

### 2. Service Problems
\`\`\`bash
k8sgpt analyze --filter Service --explain
\`\`\`

### 3. Deployment Analysis
\`\`\`bash
k8sgpt analyze --filter Deployment --explain
\`\`\`

### 4. Full Cluster Scan
\`\`\`bash
k8sgpt analyze --explain
\`\`\`

## Available Models

- **mistral:7b** - Fast, efficient (recommended for demos)
- **llama2:13b** - More comprehensive analysis
- **orca-mini:latest** - Lightweight option

## Configuration Files

- Config Directory: \`~/.k8sgpt\`
- Model Switcher: \`~/.k8sgpt/switch-model.sh\`
- Ollama Service: \`http://localhost:11434\`

## Troubleshooting

### K8sGPT not finding issues
\`\`\`bash
# Clear cache and re-analyze
k8sgpt analyze --no-cache
\`\`\`

### Model switching issues
\`\`\`bash
# Check available models
curl -s http://localhost:11434/api/tags | jq '.models[].name'

# Reset authentication
k8sgpt auth remove --backends ollama
k8sgpt auth add --backend ollama --baseurl http://localhost:11434 --model mistral:7b
\`\`\`

### Slow analysis
\`\`\`bash
# Use faster model
~/.k8sgpt/switch-model.sh orca-mini:latest

# Analyze without explanation for speed
k8sgpt analyze --namespace demo
\`\`\`
EOF
    
    log_success "Usage guide created: k8sgpt-usage-guide.md"
}

main() {
    print_banner
    
    check_prerequisites
    install_k8sgpt
    configure_k8sgpt
    configure_additional_models
    test_k8sgpt_functionality
    create_usage_guide
    
    echo ""
    echo "🎉 K8sGPT Setup Complete!"
    echo "======================================="
    echo "Installation: Homebrew"
    echo "Version: $(k8sgpt version | head -n1)"
    echo "Backend: Ollama ($OLLAMA_URL)"
    echo "Default Model: $DEFAULT_MODEL"
    echo "Config Directory: $K8SGPT_CONFIG_DIR"
    echo "Usage Guide: k8sgpt-usage-guide.md"
    echo "======================================="
    
    log_success "K8sGPT setup completed successfully!"
    log_info "Next steps:"
    log_info "  1. Run: ./scripts/setup-demo.sh"
    log_info "  2. Try: k8sgpt analyze --explain"
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi