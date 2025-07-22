#!/bin/bash

# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# ELK Cluster Deployment Script
# Automatically generates passwords and deploys ELK cluster by roles

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
    exit 1
}

# Check if Ansible is installed
check_ansible() {
    if ! command -v ansible-playbook &> /dev/null; then
        log_error "Ansible is not installed. Please install Ansible first."
    fi
}

# Generate passwords
generate_passwords() {
    log_info "Generating ELK cluster passwords..."
    if [ ! -f ".vault_pass.txt" ]; then
        log_warning "'.vault_pass.txt' not found. Please create it with your vault password."
        log_warning "Example: echo 'your_secret_vault_password' > .vault_pass.txt"
        log_error "Cannot proceed without .vault_pass.txt for vault encryption."
    fi

    ansible-playbook generate-passwords.yml --vault-password-file .vault_pass.txt
    log_success "Passwords generated and saved to 'passwords/' directory."
}

# Deploy ELK cluster
deploy_elk() {
    log_info "Deploying ELK cluster..."
    if [ ! -d "passwords" ] || [ -z "$(ls -A passwords)" ]; then
        log_error "Password vault files not found in 'passwords/' directory. Please run with --passwords first or ensure passwords are generated."
    fi

    # Include all vault files from the passwords directory
    VAULT_ARGS=""
    for vault_file in passwords/*.yml; do
        if [ -f "$vault_file" ]; then
            VAULT_ARGS+=" --vault-id @$vault_file"
        fi
    done
    ansible-playbook ansible-elk-cluster.yml -i inventory/hosts.yml --vault-password-file .vault_pass.txt $VAULT_ARGS
    log_success "ELK cluster deployment completed."
}

# Deploy by specific role
deploy_by_role() {
    local role=$1
    log_info "Deploying $role role..."

    if [ ! -d "passwords" ] || [ -z "$(ls -A passwords)" ]; then
        log_error "Password vault files not found in 'passwords/' directory. Please run with --passwords first or ensure passwords are generated."
    fi

    # Include all vault files from the passwords directory
    VAULT_ARGS=""
    for vault_file in passwords/*.yml; do
        if [ -f "$vault_file" ]; then
            VAULT_ARGS+=" --vault-id @$vault_file"
        fi
    done

    # Deploy specific role using tags
    case $role in
        elasticsearch)
            ansible-playbook ansible-elk-cluster.yml -i inventory/hosts.yml --vault-password-file .vault_pass.txt $VAULT_ARGS --tags "elasticsearch"
            ;;
        logstash)
            ansible-playbook ansible-elk-cluster.yml -i inventory/hosts.yml --vault-password-file .vault_pass.txt $VAULT_ARGS --tags "logstash"
            ;;
        kibana)
            ansible-playbook ansible-elk-cluster.yml -i inventory/hosts.yml --vault-password-file .vault_pass.txt $VAULT_ARGS --tags "kibana"
            ;;
        system)
            ansible-playbook ansible-elk-cluster.yml -i inventory/hosts.yml --vault-password-file .vault_pass.txt $VAULT_ARGS --tags "system"
            ;;
        *)
            log_error "Unknown role: $role. Available roles: elasticsearch, logstash, kibana, system"
            ;;
    esac

    log_success "$role role deployment completed."
}

# Display usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help                    Show this help message"
    echo "  -p, --passwords               Generate passwords only"
    echo "  -d, --deploy                  Deploy full ELK cluster (requires existing passwords)"
    echo "  -f, --full                    Generate passwords and deploy full cluster (default)"
    echo "  -r, --role ROLE               Deploy specific role only"
    echo "                                Available roles: elasticsearch, logstash, kibana, system"
    echo ""
    echo "Examples:"
    echo "  $0                            # Generate passwords and deploy full cluster"
    echo "  $0 -p                         # Generate passwords only"
    echo "  $0 -d                         # Deploy full cluster (requires existing passwords)"
    echo "  $0 -r elasticsearch           # Deploy Elasticsearch only"
    echo "  $0 -r logstash                # Deploy Logstash only"
    echo "  $0 -r kibana                  # Deploy Kibana only"
    echo "  $0 -r system                  # Deploy system configuration only"
    echo ""
    echo "Deployment Order (if deploying by roles):"
    echo "  1. system (基础系统配置)"
    echo "  2. elasticsearch (Elasticsearch 集群)"
    echo "  3. logstash (Logstash 服务)"
    echo "  4. kibana (Kibana 界面)"
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
        -r|--role)
            if [ -z "$2" ]; then
                log_error "Role not specified. Use -r ROLE or --role ROLE"
            fi
            check_ansible
            deploy_by_role "$2"
            ;;
        -f|--full|"")
            check_ansible
            generate_passwords
            deploy_elk
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            ;;
    esac
}

# Run main function
main "$@"