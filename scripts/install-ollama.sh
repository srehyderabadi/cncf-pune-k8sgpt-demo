#!/bin/bash

# 🦙 Ollama Installation & LLM Setup Script
# Author: CNCF Pune Demo Project
# Description: Installs Ollama, downloads models, and validates setup

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
OLLAMA_HOST="0.0.0.0:11434"
OLLAMA_CONFIG_DIR="$HOME/.ollama"
MODELS=("mistral:7b" "llama2:13b" "orca-mini:latest")

print_banner() {
    echo "======================================================"
    echo "🦙 Ollama Installation & LLM Setup"
    echo "======================================================"
    echo "This script will:"
    echo "  ✅ Install Ollama via Homebrew"
    echo "  🔧 Configure Ollama for external access"
    echo "  📥 Download LLM models: ${MODELS[*]}"
    echo "  🧪 Test model functionality"
    echo "  ✅ Validate API endpoints"
    echo "======================================================"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS. Detected: $OSTYPE"
        exit 1
    fi
    
    # Check Homebrew
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew is not installed. Please install from: https://brew.sh/"
        exit 1
    fi
    log_success "Homebrew found: $(brew --version | head -n1)"
    
    # Check available disk space (models are large)
    available_space=$(df -h . | tail -1 | awk '{print $4}' | sed 's/Gi*//')
    if [[ $available_space -lt 10 ]]; then
        log_warning "Low disk space detected: ${available_space}GB. LLM models require 10GB+."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    log_success "Sufficient disk space available: ${available_space}GB"
    
    # Check if jq is installed (for JSON processing)
    if ! command -v jq &> /dev/null; then
        log_info "Installing jq for JSON processing..."
        brew install jq
    fi
}

install_ollama() {
    log_info "Installing Ollama..."
    
    # Stop any running Ollama processes
    pkill ollama 2>/dev/null || true
    
    # Install Ollama via Homebrew
    if ! command -v ollama &> /dev/null; then
        log_info "Installing Ollama via Homebrew..."
        brew install ollama
    else
        log_info "Ollama already installed, checking for updates..."
        brew upgrade ollama || log_info "Ollama is up to date"
    fi
    
    log_success "Ollama installation completed"
}

configure_ollama() {
    log_info "Configuring Ollama for external access..."
    
    # Create Ollama config directory
    mkdir -p "$OLLAMA_CONFIG_DIR"
    
    # Create or update the Ollama config file
    cat > "$OLLAMA_CONFIG_DIR/config.json" << EOF
{
    "host": "${OLLAMA_HOST}",
    "origins": ["*"],
    "models_path": "${OLLAMA_CONFIG_DIR}/models"
}
EOF
    
    log_success "Ollama configured to listen on ${OLLAMA_HOST}"
}

start_ollama_service() {
    log_info "Starting Ollama service..."
    
    # Set environment variables
    export OLLAMA_HOST="$OLLAMA_HOST"
    
    # Start Ollama in background
    nohup ollama serve > "$OLLAMA_CONFIG_DIR/ollama.log" 2>&1 &
    OLLAMA_PID=$!
    
    # Wait for service to start
    log_info "Waiting for Ollama service to start..."
    for i in {1..30}; do
        if curl -s "http://localhost:11434/api/tags" > /dev/null 2>&1; then
            log_success "Ollama service is running (PID: $OLLAMA_PID)"
            return 0
        fi
        sleep 2
        echo -n "."
    done
    
    log_error "Ollama service failed to start. Check logs at: $OLLAMA_CONFIG_DIR/ollama.log"
    exit 1
}

download_models() {
    log_info "Downloading LLM models..."
    
    for model in "${MODELS[@]}"; do
        log_info "Downloading model: $model"
        
        # Check if model already exists
        if ollama list | grep -q "$model"; then
            log_success "Model $model already exists, skipping download"
            continue
        fi
        
        # Download model with progress
        if ollama pull "$model"; then
            log_success "Successfully downloaded: $model"
        else
            log_error "Failed to download: $model"
            continue
        fi
        
        # Verify model download
        if ollama list | grep -q "$model"; then
            log_success "Model $model verified in local registry"
        else
            log_error "Model $model not found after download"
        fi
    done
}

test_models() {
    log_info "Testing model functionality..."
    
    for model in "${MODELS[@]}"; do
        if ! ollama list | grep -q "$model"; then
            log_warning "Skipping test for $model (not downloaded)"
            continue
        fi
        
        log_info "Testing model: $model"
        
        # Test model with simple prompt
        response=$(ollama run "$model" "Say hello in one word" 2>/dev/null || echo "ERROR")
        
        if [[ "$response" == "ERROR" ]]; then
            log_error "Model $model failed test"
        else
            log_success "Model $model test passed: $response"
        fi
    done
}

validate_api_endpoints() {
    log_info "Validating Ollama API endpoints..."
    
    # Test main API endpoint
    if ! curl -s "http://localhost:11434/api/tags" > /dev/null; then
        log_error "API endpoint not responding"
        return 1
    fi
    
    # Get list of available models
    models_json=$(curl -s "http://localhost:11434/api/tags")
    model_count=$(echo "$models_json" | jq '.models | length')
    
    if [[ $model_count -gt 0 ]]; then
        log_success "API endpoint active with $model_count models available"
        
        # Display available models
        echo "Available models:"
        echo "$models_json" | jq -r '.models[] | "  - \(.name) (\(.size / 1024 / 1024 / 1024 | round)GB)"'
    else
        log_error "No models found via API"
        return 1
    fi
    
    # Test generation API with first available model
    first_model=$(echo "$models_json" | jq -r '.models[0].name')
    log_info "Testing generation API with model: $first_model"
    
    response=$(curl -s -X POST "http://localhost:11434/api/generate" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$first_model\",
            \"prompt\": \"What is Kubernetes in one sentence?\",
            \"stream\": false
        }" | jq -r '.response' 2>/dev/null || echo "ERROR")
    
    if [[ "$response" != "ERROR" ]] && [[ -n "$response" ]]; then
        log_success "Generation API test passed"
        echo "Sample response: $response"
    else
        log_error "Generation API test failed"
    fi
}

create_ollama_service_info() {
    log_info "Creating Ollama service information file..."
    
    cat > "ollama-service-info.txt" << EOF
=== Ollama Service Information ===
Service URL: http://localhost:11434
Config Directory: $OLLAMA_CONFIG_DIR
Log File: $OLLAMA_CONFIG_DIR/ollama.log

=== API Endpoints ===
List Models: GET http://localhost:11434/api/tags
Generate: POST http://localhost:11434/api/generate
Pull Model: POST http://localhost:11434/api/pull

=== Available Models ===
$(ollama list 2>/dev/null || echo "Run 'ollama list' to see models")

=== Usage Examples ===
# CLI usage
ollama run mistral:7b "Explain Docker containers"

# API usage
curl -X POST http://localhost:11434/api/generate \\
  -H "Content-Type: application/json" \\
  -d '{
    "model": "mistral:7b",
    "prompt": "What is Kubernetes?",
    "stream": false
  }'

=== K8sGPT Integration ===
# Configure K8sGPT to use Ollama
k8sgpt auth add --backend ollama --baseurl http://localhost:11434 --model mistral:7b
k8sgpt auth default --provider ollama
EOF
    
    log_success "Service information saved to: ollama-service-info.txt"
}

cleanup_on_error() {
    log_error "Script failed. Cleaning up..."
    pkill ollama 2>/dev/null || true
}

main() {
    print_banner
    
    # Set trap for cleanup on error
    trap cleanup_on_error ERR
    
    check_prerequisites
    install_ollama
    configure_ollama
    start_ollama_service
    download_models
    test_models
    validate_api_endpoints
    create_ollama_service_info
    
    echo ""
    echo "🎉 Ollama Setup Complete!"
    echo "======================================="
    echo "Service URL: http://localhost:11434"
    echo "Models Downloaded: ${MODELS[*]}"
    echo "Config Directory: $OLLAMA_CONFIG_DIR"
    echo "Service Info: ollama-service-info.txt"
    echo "======================================="
    
    log_success "Ollama setup completed successfully!"
    log_info "Next steps:"
    log_info "  1. Run: ./scripts/install-k8sgpt.sh"
    log_info "  2. Run: ./scripts/setup-demo.sh"
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi