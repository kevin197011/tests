#!/bin/bash

# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# ELK Cluster Deployment Script
# Automatically generates passwords and deploys ELK cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Ansible is installed
check_ansible() {
    if ! command -v ansible-playbook &> /dev/null; then
        log_error "Ansible is not installed. Please install Ansible first."
        exit 1
    fi
}

# Generate passwords
generate_passwords() {
    log_info "Generating ELK cluster passwords..."

    if [ -f "./passwords/vault.yml" ]; then
        log_warning "Passwords already exist. Skipping password generation."
        log_info "If you want to regenerate passwords, delete ./passwords/ directory first."
        return 0
    fi

    ansible-playbook generate-passwords.yml

    if [ $? -eq 0 ]; then
        log_success "Passwords generated successfully!"
    else
        log_error "Failed to generate passwords!"
        exit 1
    fi
}

# Deploy ELK cluster
deploy_elk() {
    log_info "Starting ELK cluster deployment..."

    # Check if vault file exists
    if [ ! -f "./passwords/vault.yml" ]; then
        log_error "Vault file not found. Please run password generation first."
        exit 1
    fi

    # Run the main deployment playbook
    ansible-playbook ansible-elk-cluster.yml --extra-vars "@./passwords/vault.yml"

    if [ $? -eq 0 ]; then
        log_success "ELK cluster deployment completed successfully!"
    else
        log_error "ELK cluster deployment failed!"
        exit 1
    fi
}

# Display usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -p, --passwords     Generate passwords only"
    echo "  -d, --deploy        Deploy ELK cluster only (requires existing passwords)"
    echo "  -f, --full          Generate passwords and deploy (default)"
    echo ""
    echo "Examples:"
    echo "  $0                  # Generate passwords and deploy"
    echo "  $0 -p               # Generate passwords only"
    echo "  $0 -d               # Deploy only (requires existing passwords)"
}

# Main script logic
main() {
    case "${1:-}" in
        -h|--help)
            show_usage
            exit 0
            ;;
        -p|--passwords)
            check_ansible
            generate_passwords
            ;;
        -d|--deploy)
            check_ansible
            deploy_elk
            ;;
        -f|--full|"")
            check_ansible
            generate_passwords
            deploy_elk
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"