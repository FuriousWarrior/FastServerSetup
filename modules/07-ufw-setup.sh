#!/bin/bash
#===============================================================================
# Module 07: UFW Firewall Setup
#===============================================================================

module_ufw_setup() {
    info "Настройка UFW firewall..."
    
    # Install UFW
    apt install -y ufw
    
    # Reset UFW
    ufw --force reset
    
    # Default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH port
    ufw allow "${SSH_PORT}" comment 'SSH Access'
    
    # Allow other ports
    for port in "${ALLOWED_PORTS[@]}"; do
        [[ "${port}" != "${SSH_PORT}" ]] && ufw allow "${port}"
    done
    
    # Enable UFW
    echo "y" | ufw enable
    
    # Status
    ufw status verbose
    
    success "UFW настроен и включен"
}

module_ufw_setup