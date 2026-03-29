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
    
    # Проверка существования пользователя
    if ! id "${ssh_user}" >/dev/null 2>&1; then
        warn "Пользователь ${ssh_user} не существует"
        return 1
    fi
    
    # Определение домашней директории
    local home_dir
    home_dir=$(getent passwd "${ssh_user}" | cut -d: -f6)
    
    if [[ -z "${home_dir}" ]]; then
        warn "Не удалось определить домашнюю директорию пользователя ${ssh_user}"
        return 1
    fi
    
    local ssh_dir="${home_dir}/.ssh"
    local auth_keys="${ssh_dir}/authorized_keys"
    
    # Создание .ssh директории
    mkdir -p "${ssh_dir}"
    chmod 700 "${ssh_dir}"
    chown "${ssh_user}:${ssh_user}" "${ssh_dir}"
    
    # Очистка файла ключей
    > "${auth_keys}"
    
    # === Основная логика ===
    if [[ -n "${SSH_PUBLIC_KEY}" ]]; then
        info "Используется SSH ключ из конфигурации"
        
        # Поддержка многострочного ввода (\n и реальные переносы)
        echo -e "${SSH_PUBLIC_KEY}" >> "${auth_keys}"
    else
        echo ""
        echo "Вставьте ваш SSH публичный ключ (нажмите Enter дважды для завершения):"
        echo "=========================================="
        
        while IFS= read -r line; do
            [[ -z "${line}" ]] && break
            echo "${line}" >> "${auth_keys}"
        done
    fi
    
    # Проверка что ключ действительно добавлен
    if [[ ! -s "${auth_keys}" ]]; then
        warn "SSH ключ не добавлен!"
        return 1
    fi
    
    # Права доступа
    chmod 600 "${auth_keys}"
    chown "${ssh_user}:${ssh_user}" "${auth_keys}"
    
    success "SSH ключ(и) добавлен(ы) для пользователя: ${ssh_user}"
}

module_ssh_key