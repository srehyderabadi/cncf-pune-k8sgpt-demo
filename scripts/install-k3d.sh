#!/bin/bash

# 🐳 K3D Installation & Cluster Setup Script
# Author: CNCF Pune Demo Project
# Description: Installs K3D, creates cluster, and validates setup

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
CLUSTER_NAME="cncf-pune-k3d-demo"
CLUSTER_CONFIG="k8s/k3d-cluster.yaml"

print_banner() {
    echo "======================================================"
    echo "🐳 K3D Installation & Cluster Setup"
    echo "======================================================"
    echo "This script will:"
    echo "  ✅ Check prerequisites (Docker, Homebrew)"
    echo "  🔧 Install kubectl and K3D (if needed)"
    echo "  🔍 Check for existing K3D cluster: ${CLUSTER_NAME}"
    echo "  🚀 Create or use K3D cluster"
    echo "  ✅ Validate cluster functionality"
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
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_warning "Docker not found. Installing via Homebrew..."
        brew install --cask docker
        log_info "Please start Docker Desktop and run this script again."
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is installed but not running. Please start Docker Desktop."
        exit 1
    fi
    log_success "Docker is running: $(docker --version)"
}

# Function to detect user's shell configuration file
get_shell_config() {
    local shell_name
    shell_name=$(basename "$SHELL")
    
    case "$shell_name" in
        "zsh")
            if [[ -f "$HOME/.zshrc" ]]; then
                echo "$HOME/.zshrc"
            else
                echo "$HOME/.zshrc"  # Create if doesn't exist
            fi
            ;;
        "bash")
            if [[ -f "$HOME/.bashrc" ]]; then
                echo "$HOME/.bashrc"
            elif [[ -f "$HOME/.bash_profile" ]]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.bashrc"  # Default for bash
            fi
            ;;
        "fish")
            echo "$HOME/.config/fish/config.fish"
            ;;
        *)
            # Default fallback - try common locations
            if [[ -f "$HOME/.bashrc" ]]; then
                echo "$HOME/.bashrc"
            elif [[ -f "$HOME/.bash_profile" ]]; then
                echo "$HOME/.bash_profile"
            elif [[ -f "$HOME/.zshrc" ]]; then
                echo "$HOME/.zshrc"
            else
                echo "$HOME/.profile"  # Most universal fallback
            fi
            ;;
    esac
}

install_tools() {
    log_info "Installing K3D and kubectl..."
    
    # Install kubectl
    if ! command -v kubectl &> /dev/null; then
        log_info "Installing kubectl..."
        brew install kubectl
    else
        log_success "kubectl already installed: $(kubectl version --client --short)"
    fi
    
    # Install k3d
    if ! command -v k3d &> /dev/null; then
        log_info "Installing k3d..."
        brew install k3d
    else
        log_success "k3d already installed: $(k3d version)"
    fi
    
    # Install kubecolor for better kubectl output
    if ! command -v kubecolor &> /dev/null; then
        log_info "Installing kubecolor for better kubectl output..."
        brew install kubecolor
        
        # Detect user's shell configuration file
        local shell_config
        shell_config=$(get_shell_config)
        
        # Add alias to shell config
        if ! grep -q "alias kubectl=\"kubecolor\"" "$shell_config" 2>/dev/null; then
            # Create directory if it doesn't exist (for fish shell)
            mkdir -p "$(dirname "$shell_config")"
            
            echo 'alias kubectl="kubecolor"' >> "$shell_config"
            local shell_name
            shell_name=$(basename "$SHELL")
            log_info "Added kubectl alias to $shell_config ($shell_name shell detected)."
            log_info "Reload your shell or run 'source $shell_config' to use colorized output."
        else
            log_info "kubectl alias already exists in shell configuration"
        fi
    fi
}

create_cluster() {
    log_info "Creating K3D cluster: ${CLUSTER_NAME}"
    
    # Check if cluster already exists
    if k3d cluster list | grep -q "${CLUSTER_NAME}"; then
        echo ""
        log_warning "Cluster '${CLUSTER_NAME}' already exists!"
        echo ""
        echo "Existing cluster details:"
        k3d cluster list | grep "${CLUSTER_NAME}" || true
        echo ""
        
        # Handle automated modes
        if [[ "$FORCE_RECREATE" == "true" ]]; then
            log_info "--force-recreate flag set. Deleting existing cluster..."
            k3d cluster delete "${CLUSTER_NAME}"
            log_success "Existing cluster deleted"
        elif [[ "$USE_EXISTING" == "true" ]]; then
            log_info "--use-existing flag set. Using existing cluster..."
            kubectl config use-context "k3d-${CLUSTER_NAME}" 2>/dev/null || {
                log_error "Failed to set context for existing cluster. It may be corrupted."
                log_info "Try running: k3d cluster delete ${CLUSTER_NAME}"
                exit 1
            }
            log_success "Using existing cluster: ${CLUSTER_NAME}"
            return 0  # Skip cluster creation, jump to validation
        else
            # Interactive mode
            log_info "Options:"
            log_info "  1. Delete and recreate the cluster (recommended for clean demo)"
            log_info "  2. Use the existing cluster (may have old configurations)"
            log_info "  3. Exit and manage cluster manually"
            echo ""
            read -p "What would you like to do? [1/2/3] (default: 1): " choice
            choice=${choice:-1}
            
            case $choice in
                1)
                    log_info "Deleting existing cluster..."
                    k3d cluster delete "${CLUSTER_NAME}"
                    log_success "Existing cluster deleted"
                    ;;
                2)
                    log_info "Using existing cluster..."
                    # Set kubeconfig context to existing cluster
                    kubectl config use-context "k3d-${CLUSTER_NAME}" 2>/dev/null || {
                        log_error "Failed to set context for existing cluster. It may be corrupted."
                        log_info "Try running: k3d cluster delete ${CLUSTER_NAME}"
                        exit 1
                    }
                    log_success "Using existing cluster: ${CLUSTER_NAME}"
                    return 0  # Skip cluster creation, jump to validation
                    ;;
                3)
                    log_info "Exiting. You can manually manage the cluster with:"
                    log_info "  k3d cluster delete ${CLUSTER_NAME}  # To delete"
                    log_info "  k3d cluster list                   # To list clusters"
                    exit 0
                    ;;
                *)
                    log_error "Invalid choice. Please run the script again."
                    exit 1
                    ;;
            esac
        fi
    fi
    
    # Create cluster configuration directory
    mkdir -p k8s
    
    # Create cluster using config file
    if [[ -f "${CLUSTER_CONFIG}" ]]; then
        log_info "Using existing cluster config: ${CLUSTER_CONFIG}"
        k3d cluster create --config "${CLUSTER_CONFIG}"
    else
        log_info "Creating default cluster configuration..."
        cat > "${CLUSTER_CONFIG}" << EOF
apiVersion: k3d.io/v1alpha5
kind: Simple
metadata:
  name: ${CLUSTER_NAME}
servers: 1
agents: 0
kubeAPI:
  host: "0.0.0.0"
  hostIP: "127.0.0.1"
  hostPort: "6443"
ports:
  - port: 8080:8080
    nodeFilters:
      - loadbalancer
  - port: 80:80
    nodeFilters:
      - loadbalancer
  - port: 443:443
    nodeFilters:
      - loadbalancer
options:
  k3s:
    extraArgs:
      - arg: --disable=traefik
        nodeFilters:
          - server:*
EOF
        k3d cluster create --config "${CLUSTER_CONFIG}"
    fi
    
    # Wait for cluster to be ready
    log_info "Waiting for cluster to be ready..."
    sleep 10
    
    # Set kubeconfig context
    kubectl config use-context "k3d-${CLUSTER_NAME}"
    
    log_success "Cluster created successfully!"
}

validate_cluster() {
    log_info "Validating cluster setup..."
    
    # Check nodes
    log_info "Checking cluster nodes..."
    kubectl get nodes -o wide
    
    # Check if nodes are ready
    if ! kubectl wait --for=condition=Ready nodes --all --timeout=60s; then
        log_error "Cluster nodes are not ready"
        exit 1
    fi
    log_success "All nodes are ready"
    
    # Check cluster info
    log_info "Cluster information:"
    kubectl cluster-info
    
    # Create demo namespace
    log_info "Creating demo namespace..."
    kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -
    
    # Test basic functionality
    log_info "Testing basic cluster functionality..."
    kubectl run test-pod --image=nginx:alpine --restart=Never -n demo
    kubectl wait --for=condition=Ready pod/test-pod -n demo --timeout=60s
    kubectl delete pod test-pod -n demo
    log_success "Basic functionality test passed"
    
    # Show cluster status
    echo ""
    echo "🎉 Cluster Setup Complete!"
    echo "======================================="
    echo "Cluster Name: ${CLUSTER_NAME}"
    echo "Context: k3d-${CLUSTER_NAME}"
    echo "API Server: https://127.0.0.1:6443"
    echo "LoadBalancer Ports: 80, 443, 8080"
    echo "Demo Namespace: demo"
    echo "======================================="
}

cleanup_on_error() {
    log_error "Script failed. Cleaning up..."
    if k3d cluster list | grep -q "${CLUSTER_NAME}"; then
        k3d cluster delete "${CLUSTER_NAME}"
    fi
}

main() {
    # Handle script arguments
    FORCE_RECREATE=false
    USE_EXISTING=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force-recreate)
                FORCE_RECREATE=true
                shift
                ;;
            --use-existing)
                USE_EXISTING=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "OPTIONS:"
                echo "  --force-recreate    Always delete and recreate existing cluster"
                echo "  --use-existing      Always use existing cluster if found"
                echo "  --help, -h          Show this help message"
                echo ""
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    print_banner
    
    # Set trap for cleanup on error
    trap cleanup_on_error ERR
    
    check_prerequisites
    install_tools
    create_cluster
    validate_cluster
    
    log_success "K3D setup completed successfully!"
    log_info "Next steps:"
    log_info "  1. Run: ./scripts/install-ollama.sh"
    log_info "  2. Run: ./scripts/install-k8sgpt.sh"
    log_info "  3. Run: ./scripts/setup-demo.sh"
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi