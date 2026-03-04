#!/bin/bash
#===============================================================================
# Module 09: Fail2Ban Setup (sed/awk version)
#===============================================================================

module_fail2ban_setup() {
    info "Установка и настройка Fail2Ban..."
    
    # Install
    apt install -y fail2ban
    
    # Create local config from template
    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    
    # Get server external IP
    local external_ip=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    [[ -z "${external_ip}" ]] && external_ip="0.0.0.0"
    
    # Use sed to modify jail.local
    local jail_file="/etc/fail2ban/jail.local"
    
    # Modify DEFAULT section using sed
    sed -i "s/^bantime.*/bantime = ${FAIL2BAN_BANTIME}/" "${jail_file}"
    sed -i "s/^findtime.*/findtime = ${FAIL2BAN_FINDTIME}/" "${jail_file}"
    sed -i "s/^maxretry.*/maxretry = ${FAIL2BAN_MAXRETRY}/" "${jail_file}"
    sed -i "s/^banaction.*/banaction = ufw/" "${jail_file}"
    
    # Update ignoreip with external IP using sed
    sed -i "s/^ignoreip.*/ignoreip = 127.0.0.1\/8 ::1 ${external_ip}/" "${jail_file}"
    
    # Enable sshd jail using awk (more complex pattern matching)
    awk '
    /^\[sshd\]/ { in_sshd=1; print; next }
    in_sshd && /^enabled/ { gsub(/enabled.*/, "enabled = true"); print; in_sshd=0; next }
    in_sshd && /^port/ { gsub(/port.*/, "port = '"${SSH_PORT}"'"); print; next }
    in_sshd && /^maxretry/ { gsub(/maxretry.*/, "maxretry = '"${FAIL2BAN_MAXRETRY}"'"); print; next }
    in_sshd && /^findtime/ { gsub(/findtime.*/, "findtime = '"${FAIL2BAN_FINDTIME}"'"); print; next }
    in_sshd && /^bantime/ { gsub(/bantime.*/, "bantime = '"${FAIL2BAN_BANTIME}"'"); print; next }
    in_sshd && /^logpath/ { gsub(/logpath.*/, "logpath = /var/log/auth.log"); print; in_sshd=0; next }
    { print }
    ' "${jail_file}" > "${jail_file}.tmp" && mv "${jail_file}.tmp" "${jail_file}"
    
    # If sshd section doesn't exist, add it using sed
    if ! grep -q "^\[sshd\]" "${jail_file}"; then
        cat >> "${jail_file}" << EOF

[sshd]
enabled = true
port = ${SSH_PORT}
maxretry = ${FAIL2BAN_MAXRETRY}
findtime = ${FAIL2BAN_FINDTIME}
bantime = ${FAIL2BAN_BANTIME}
ignoreip = 127.0.0.1/8 ::1 ${external_ip}
logpath = /var/log/auth.log
EOF
    fi
    
    # Verify configuration using awk
    info "Проверка конфигурации Fail2Ban:"
    awk '/^\[sshd\]/,/^\[/' "${jail_file}" | head -10
    
    # Enable and start
    systemctl enable fail2ban
    systemctl restart fail2ban
    
    # Status
    sleep 2
    fail2ban-client status sshd 2>/dev/null || fail2ban-client status
    
    success "Fail2Ban настроен (внешний IP: ${external_ip}, порт SSH: ${SSH_PORT})"
}

module_fail2ban_setup