#!/bin/bash

# 🎯 CNCF Pune K8sGPT Demo - One Command Setup
# Author: CNCF Pune Demo Project
# Description: Complete setup for K8sGPT with Ollama demo environment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_demo() { echo -e "${PURPLE}[DEMO]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

print_banner() {
    echo ""
    echo "=================================================================="
    echo "🎯 CNCF Pune K8sGPT Demo - Complete Setup"
    echo "=================================================================="
    echo "🚀 This will set up:"
    echo "   • K3D Kubernetes cluster"
    echo "   • Ollama with multiple LLM models"
    echo "   • K8sGPT for AI-powered troubleshooting"
    echo "   • Demo application with failure scenarios"
    echo ""
    echo "📋 Prerequisites:"
    echo "   • macOS (tested on Monterey+)"
    echo "   • Docker Desktop running"
    echo "   • Homebrew installed"
    echo "   • 10GB+ free disk space"
    echo "   • 8GB+ RAM recommended"
    echo "=================================================================="
    echo ""
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This demo is designed for macOS. Detected: $OSTYPE"
        log_info "For Linux support, please see the documentation or contribute!"
        exit 1
    fi
    
    # Check Homebrew
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew is required but not installed."
        log_info "Install it from: https://brew.sh/"
        log_info "Then run this script again."
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is required but not installed."
        log_info "Install Docker Desktop from: https://www.docker.com/products/docker-desktop"
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is installed but not running."
        log_info "Please start Docker Desktop and run this script again."
        exit 1
    fi
    
    # Check disk space
    available_space=$(df -h . | tail -1 | awk '{print $4}' | sed 's/Gi*//')
    if [[ ${available_space%.*} -lt 10 ]]; then
        log_warning "Low disk space: ${available_space}GB available"
        log_warning "LLM models require 10GB+. Continue? (y/N)"
        read -n 1 -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Setup cancelled. Free up disk space and try again."
            exit 1
        fi
    fi
    
    log_success "Prerequisites check passed!"
}

run_setup_sequence() {
    log_info "Starting complete setup sequence..."
    
    # Make all scripts executable
    chmod +x scripts/*.sh
    
    log_step "Step 1/4: Setting up K3D cluster..."
    if ./scripts/install-k3d.sh; then
        log_success "K3D setup completed successfully!"
    else
        log_error "K3D setup failed"
        exit 1
    fi
    
    log_step "Step 2/4: Installing Ollama and LLM models..."
    log_warning "This step will download several GB of model data..."
    if ./scripts/install-ollama.sh; then
        log_success "Ollama setup completed successfully!"
    else
        log_error "Ollama setup failed"
        exit 1
    fi
    
    log_step "Step 3/4: Installing and configuring K8sGPT..."
    if ./scripts/install-k8sgpt.sh; then
        log_success "K8sGPT setup completed successfully!"
    else
        log_error "K8sGPT setup failed"
        exit 1
    fi
    
    log_step "Step 4/4: Setting up demo application and scenarios..."
    if ./scripts/setup-demo.sh --skip-install; then
        log_success "Demo setup completed successfully!"
    else
        log_error "Demo setup failed"
        exit 1
    fi
}

validate_setup() {
    log_info "Validating complete setup..."
    
    if ./scripts/validate-setup.sh; then
        log_success "All validations passed! 🎉"
        return 0
    else
        log_warning "Some validations failed. Check the output above."
        return 1
    fi
}

show_next_steps() {
    echo ""
    echo "🎉 Setup Complete! Your K8sGPT demo environment is ready!"
    echo "=================================================================="
    echo ""
    echo "🚀 Quick Demo Commands:"
    echo "   ./scenarios/run-scenario.sh 1          # Deploy ImagePullBackOff scenario"
    echo "   k8sgpt analyze --namespace demo --explain  # AI analysis"
    echo "   ./scenarios/run-scenario.sh 1 fix      # Fix the issue"
    echo ""
    echo "🌐 Demo Application:"
    echo "   http://cncf.vg.local                   # Demo web app"
    echo ""
    echo "🔧 Useful Commands:"
    echo "   kubectl get nodes                      # Check cluster"
    echo "   ollama list                           # Check models"
    echo "   k8sgpt auth list                      # Check K8sGPT config"
    echo ""
    echo "📚 Documentation:"
    echo "   README.md                             # Project overview"
    echo "   PROJECT_STRUCTURE.md                  # Project structure guide"
    echo "   DEMO_GUIDE.md                         # Complete demo walkthrough (generated)"
    echo "   QUICK_REFERENCE.md                    # Quick commands (generated)"
    echo "   docs/                                 # Detailed setup documentation"
    echo ""
    echo "🧪 Validation:"
    echo "   ./scripts/validate-setup.sh           # Re-run validation"
    echo ""
    echo "=================================================================="
    log_success "Happy demoing! 🎯"
}

cleanup_on_error() {
    log_error "Setup failed. Cleaning up partial installation..."
    
    # Clean up K3D cluster if it exists
    if command -v k3d &> /dev/null && k3d cluster list | grep -q "cncf-pune-k8sgpt-demo"; then
        log_info "Removing K3D cluster..."
        k3d cluster delete cncf-pune-k8sgpt-demo || true
    fi
    
    # Stop Ollama if running
    pkill ollama 2>/dev/null || true
    
    log_info "Cleanup completed. You can re-run this script to try again."
    log_info "If you continue to have issues, please check the troubleshooting guide in docs/"
}

# Main execution
main() {
    # Set trap for cleanup on error
    trap cleanup_on_error ERR
    
    print_banner
    
    # Check if user wants to proceed
    echo "Do you want to proceed with the complete setup? (y/N)"
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Setup cancelled by user."
        echo ""
        log_info "You can also run individual setup scripts:"
        log_info "  ./scripts/install-k3d.sh      # K3D only"
        log_info "  ./scripts/install-ollama.sh   # Ollama only"
        log_info "  ./scripts/install-k8sgpt.sh   # K8sGPT only"
        exit 0
    fi
    
    check_prerequisites
    run_setup_sequence
    
    echo ""
    log_info "Running final validation..."
    if validate_setup; then
        show_next_steps
    else
        log_warning "Setup completed but with some validation warnings."
        log_info "You can still proceed with the demo, but some features may not work properly."
        show_next_steps
    fi
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Complete setup for CNCF Pune K8sGPT Demo"
        echo ""
        echo "OPTIONS:"
        echo "  --help, -h     Show this help message"
        echo "  --validate     Only run validation"
        echo "  --clean        Clean up existing installation"
        echo ""
        echo "This script will install and configure:"
        echo "  • K3D Kubernetes cluster"
        echo "  • Ollama with LLM models (Mistral, Llama2, Orca Mini)"
        echo "  • K8sGPT for AI-powered Kubernetes troubleshooting"
        echo "  • Demo application with failure scenarios"
        echo ""
        echo "For more information, see README.md"
        exit 0
        ;;
    --validate)
        log_info "Running validation only..."
        validate_setup
        exit $?
        ;;
    --clean)
        log_info "Cleaning up existing installation..."
        cleanup_on_error
        log_success "Cleanup completed!"
        exit 0
        ;;
    "")
        # No arguments, run main setup
        main
        ;;
    *)
        log_error "Unknown option: $1"
        log_info "Use --help for usage information"
        exit 1
        ;;
esac