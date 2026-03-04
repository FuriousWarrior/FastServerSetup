#!/bin/bash
#===============================================================================
# Module 06: SWAP Configuration
#===============================================================================

module_swap_setup() {
    info "Проверка и настройка SWAP..."
    
    local swap_exists=$(swapon --show --noheadings | wc -l)
    local swap_size=$(free -m | awk '/Swap:/ {print $2}')
    
    info "Текущий SWAP: ${swap_size} MB (найден разделов: ${swap_exists})"
    
    if [[ ${swap_exists} -gt 0 ]] && [[ ${swap_size} -gt 512 ]]; then
        success "SWAP уже настроен и достаточен (${swap_size} MB)"
        return 0
    fi
    
    info "Создание SWAP файла ${SWAP_SIZE}..."
    
    # Remove old swap if exists
    [[ -f "${SWAP_FILE}" ]] && swapoff "${SWAP_FILE}" && rm -f "${SWAP_FILE}"
    
    # Create swap file
    fallocate -l "${SWAP_SIZE}" "${SWAP_FILE}"
    chmod 600 "${SWAP_FILE}"
    mkswap "${SWAP_FILE}"
    swapon "${SWAP_FILE}"
    
    # Add to fstab
    if ! grep -q "${SWAP_FILE}" /etc/fstab; then
        echo "${SWAP_FILE} none swap sw 0 0" >> /etc/fstab
        info "SWAP добавлен в /etc/fstab"
    fi
    
    # Verify
    local new_swap=$(free -m | awk '/Swap:/ {print $2}')
    success "SWAP создан: ${new_swap} MB"
}

module_swap_setup