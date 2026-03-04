#!/bin/bash
#===============================================================================
# Module 03: Time Synchronization
#===============================================================================

module_time_sync() {
    info "Настройка синхронизации времени..."
    
    # Install chrony
    apt install -y chrony
    
    # Set timezone
    timedatectl set-timezone "${TIMEZONE}"
    
    # Enable and start chrony
    systemctl enable chrony
    systemctl start chrony
    
    # Force sync
    chronyc -a makestep
    
    # Verify
    info "Текущее время: $(date)"
    info "Часовой пояс: $(timedatectl | grep 'Time zone')"
    
    success "Синхронизация времени настроена"
}

module_time_sync