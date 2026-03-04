#!/bin/bash
#===============================================================================
# Module 05: SSH Hardening
#===============================================================================

module_ssh_hardening() {
    info "Hardening SSH конфигурации..."
    
    local ssh_config="/etc/ssh/sshd_config"
    local backup="${ssh_config}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Backup
    cp "${ssh_config}" "${backup}"
    info "Резервная копия SSH конфига: ${backup}"
    
    # Modify configuration
    sed -i "s/^#*Port.*/Port ${SSH_PORT}/" "${ssh_config}"
    sed -i "s/^#*PermitRootLogin.*/PermitRootLogin ${SSH_PERMIT_ROOT}/" "${ssh_config}"
    sed -i "s/^#*PermitEmptyPasswords.*/PermitEmptyPasswords ${SSH_EMPTY_PASSWORDS}/" "${ssh_config}"
    sed -i "s/^#*PasswordAuthentication.*/PasswordAuthentication ${SSH_PASSWORD_AUTH}/" "${ssh_config}"
    
    # Add security settings if not present
    grep -q "^PubkeyAuthentication" "${ssh_config}" || echo "PubkeyAuthentication yes" >> "${ssh_config}"
    grep -q "^AuthenticationMethods" "${ssh_config}" || echo "AuthenticationMethods publickey" >> "${ssh_config}"
    grep -q "^MaxAuthTries" "${ssh_config}" || echo "MaxAuthTries 3" >> "${ssh_config}"
    grep -q "^ClientAliveInterval" "${ssh_config}" || echo "ClientAliveInterval 300" >> "${ssh_config}"
    grep -q "^ClientAliveCountMax" "${ssh_config}" || echo "ClientAliveCountMax 2" >> "${ssh_config}"
    
    # Validate config
    if sshd -t; then
        success "Конфигурация SSH валидна"
        
        # Restart SSH
        systemctl restart sshd
        success "SSH перезапущен на порту ${SSH_PORT}"
        
        warn "НЕ ЗАКРЫВАЙТЕ ЭТОТ СЕАНС! Проверьте подключение к порту ${SSH_PORT}"
        read -p "Подтвердите подключение к новому порту (yes/no): " confirm
        if [[ "${confirm}" != "yes" ]]; then
            error "Восстановление оригинальной конфигурации..."
            cp "${backup}" "${ssh_config}"
            systemctl restart sshd
            exit 1
        fi
    else
        error "Ошибка в конфигурации SSH! Восстановление..."
        cp "${backup}" "${ssh_config}"
        exit 1
    fi
}

module_ssh_hardening