#!/bin/bash
#===============================================================================
# Module 01: System Update to Debian 13 (Trixie)
#===============================================================================

module_system_update() {
    info "Проверка версии Debian..."
    
    local current_version=$(cat /etc/debian_version)
    local codename=$(lsb_release -cs 2>/dev/null || grep -oP '(?<=codename=)\w+' /etc/os-release 2>/dev/null || echo "unknown")
    
    info "Текущая версия: ${current_version}, кодовое имя: ${codename}"
    
    if [[ "${codename}" == "bookworm" ]] || [[ "${current_version}" < "13" ]]; then
        warn "Требуется обновление до Debian 13 (Trixie)"
        
        # Backup sources.list
        cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d_%H%M%S)
        info "Резервная копия sources.list создана"
        
        # Update main repositories
        info "Обновление основных репозиториев..."
        sed -i 's/bookworm/trixie/g' /etc/apt/sources.list
        
        # Update custom repositories
        info "Обновление дополнительных репозиториев..."
        if [[ -d /etc/apt/sources.list.d ]]; then
            find /etc/apt/sources.list.d -type f -name "*.list" -exec sed -i 's/bookworm/trixie/g' {} \;
        fi
        
        # Update package lists
        info "Обновление списков пакетов..."
        apt update
        
        # Full upgrade
        info "Выполнение полного обновления системы..."
        DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
        
        success "Система обновлена до Debian 13"
    else
        success "Система уже на Debian 13 (Trixie)"
    fi
    
    # Install required packages
    info "Установка необходимых пакетов..."
    DEBIAN_FRONTEND=noninteractive apt install -y "${REQUIRED_PACKAGES[@]}"
    success "Пакеты установлены"


}

module_system_update