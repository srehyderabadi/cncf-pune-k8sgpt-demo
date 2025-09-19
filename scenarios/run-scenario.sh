#!/bin/bash

# Demo Scenario Runner Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
    echo "Usage: $0 <scenario-number> [action]"
    echo ""
    echo "Scenarios:"
    echo "  1 - ImagePullBackOff (missing image)"
    echo "  2 - Service selector mismatch"
    echo "  3 - Resource limits causing issues"
    echo ""
    echo "Actions:"
    echo "  deploy  - Deploy the scenario (default)"
    echo "  fix     - Apply the fix"
    echo "  clean   - Clean up the scenario"
    echo ""
    echo "Examples:"
    echo "  $0 1         # Deploy scenario 1"
    echo "  $0 1 fix     # Fix scenario 1"
    echo "  $0 2 clean   # Clean up scenario 2"
}

deploy_scenario() {
    local scenario=$1
    log_info "Deploying scenario $scenario..."
    
    # Determine the correct path - this script is in scenarios/ directory
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    SCENARIOS_DIR="$SCRIPT_DIR"
    
    case $scenario in
        1)
            log_info "Scenario 1: ImagePullBackOff - Deploying app with non-existent image"
            kubectl apply -f "$SCENARIOS_DIR/scenario-1/k8s/error_1.yaml"
            ;;
        2)
            log_info "Scenario 2: Service Mismatch - Deploying app with wrong service selector"
            kubectl apply -f "$SCENARIOS_DIR/scenario-2/k8s/error_2.yaml"
            ;;
        3)
            log_info "Scenario 3: Resource Limits - Deploying app with insufficient resources"
            kubectl apply -f "$SCENARIOS_DIR/scenario-3/k8s/error_3.yaml"
            ;;
        *)
            log_error "Invalid scenario number: $scenario"
            exit 1
            ;;
    esac
    
    log_success "Scenario $scenario deployed"
    echo ""
    log_info "Wait a few moments, then run: k8sgpt analyze --namespace demo --explain"
}

fix_scenario() {
    local scenario=$1
    log_info "Applying fix for scenario $scenario..."
    
    # Determine the correct path - this script is in scenarios/ directory
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    SCENARIOS_DIR="$SCRIPT_DIR"
    
    case $scenario in
        1)
            kubectl apply -f "$SCENARIOS_DIR/scenario-1/k8s/fix_1.yaml"
            ;;
        2)
            kubectl apply -f "$SCENARIOS_DIR/scenario-2/k8s/fix_2.yaml"
            ;;
        3)
            kubectl apply -f "$SCENARIOS_DIR/scenario-3/k8s/fix_3.yaml"
            ;;
        *)
            log_error "Invalid scenario number: $scenario"
            exit 1
            ;;
    esac
    
    log_success "Fix applied for scenario $scenario"
}

clean_scenario() {
    local scenario=$1
    log_info "Cleaning up scenario $scenario..."
    
    # Clean up any deployments, services, etc. in demo namespace
    kubectl delete deployment,service,ingress --all -n demo --ignore-not-found=true
    
    log_success "Scenario $scenario cleaned up"
}

# Main execution
if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

scenario=$1
action=${2:-deploy}

case $action in
    deploy)
        deploy_scenario $scenario
        ;;
    fix)
        fix_scenario $scenario
        ;;
    clean)
        clean_scenario $scenario
        ;;
    *)
        log_error "Invalid action: $action"
        usage
        exit 1
        ;;
esac