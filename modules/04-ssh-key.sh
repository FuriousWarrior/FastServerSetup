#!/bin/bash
#===============================================================================
# Module 04: SSH Key Setup
#===============================================================================

module_ssh_key() {
    info "Настройка SSH ключей..."
    
    # Get username
    read -p "Введите имя пользователя для SSH ключа: " ssh_user
    
    if [[ -z "${ssh_user}" ]]; then
        ssh_user="root"
    fi
    
    # Create .ssh directory
    local home_dir=$(getent passwd "${ssh_user}" | cut -d: -f6)
    local ssh_dir="${home_dir}/.ssh"
    
    mkdir -p "${ssh_dir}"
    chmod 700 "${ssh_dir}"
    chown "${ssh_user}:${ssh_user}" "${ssh_dir}"
    
    # Get public key from user
    echo ""
    echo "Вставьте ваш SSH публичный ключ (нажмите Enter дважды для завершения):"
    echo "=========================================="
    
    local auth_keys="${ssh_dir}/authorized_keys"
    > "${auth_keys}"
    
    while IFS= read -r line; do
        [[ -z "${line}" ]] && break
        echo "${line}" >> "${auth_keys}"
    done
    
    # Set permissions
    chmod 600 "${auth_keys}"
    chown "${ssh_user}:${ssh_user}" "${auth_keys}"
    
    success "SSH ключ добавлен для пользователя: ${ssh_user}"
}

module_ssh_key