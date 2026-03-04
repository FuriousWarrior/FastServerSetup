#!/bin/bash
#===============================================================================
# Module 10: External Scripts Integration
#===============================================================================

module_external_scripts() {
    info "Установка внешних скриптов..."
    
    for script_url in "${EXTERNAL_SCRIPTS[@]}"; do
        info "Загрузка: ${script_url}"
        
        if curl -fsSL "${script_url}" | bash; then
            success "Скрипт выполнен: ${script_url}"
        else
            warn "Ошибка выполнения: ${script_url}"
        fi
    done
    
    # Special handling for remnanode script
    local remna_url="https://raw.githubusercontent.com/begugla0/remnawave-node-scripts/main/remnanode-install.sh"
    local remna_file="remnanode-install.sh"
    
    if curl -O "${remna_url}" && chmod +x "${remna_file}"; then
        sudo "./${remna_file}" && rm -f "${remna_file}"
        success "RemnaNode скрипт выполнен"
    fi
    
    success "Все внешние скрипты обработаны"
}

module_external_scripts