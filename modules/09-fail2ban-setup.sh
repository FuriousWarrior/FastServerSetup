#!/bin/bash
#===============================================================================
# Module 09: Fail2Ban Setup (sed/awk version)
#===============================================================================

module_fail2ban_setup() {
    info "Установка и настройка Fail2Ban..."

    # Install
    apt install -y fail2ban

    info "Создание фильтров Fail2ban..."

   # Создание фильтра для порт-сканирования (через iptables LOG)
    cat > /etc/fail2ban/filter.d/portscan.conf << 'EOF'
[Definition]
# Детект порт-сканирования через iptables LOG
failregex = PORTSCAN.*SRC=<HOST>
ignoreregex =
EOF
    # Настройка iptables правила для логирования порт-сканов
    info "Настройка детекта порт-сканирования..."

    # Создание systemd сервиса для iptables правила (переживает перезагрузку)
    cat > /etc/systemd/system/portscan-detect.service << 'EOF'
[Unit]
Description=Portscan detection iptables rules
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c 'iptables -N PORTSCAN 2>/dev/null || true; iptables -F PORTSCAN 2>/dev/null || true; iptables -A PORTSCAN -p tcp --tcp-flags ALL NONE -j LOG --log-prefix "PORTSCAN: " --log-level 4; iptables -A PORTSCAN -p tcp --tcp-flags ALL ALL -j LOG --log-prefix "PORTSCAN: " --log-level 4; iptables -A PORTSCAN -p tcp --tcp-flags ALL FIN,URG,PSH -j LOG --log-prefix "PORTSCAN: " --log-level 4; iptables -A PORTSCAN -p tcp --tcp-flags SYN,RST SYN,RST -j LOG --log-prefix "PORTSCAN: " --log-level 4; iptables -A PORTSCAN -p tcp --tcp-flags SYN,FIN SYN,FIN -j LOG --log-prefix "PORTSCAN: " --log-level 4; iptables -D INPUT -j PORTSCAN 2>/dev/null || true; iptables -I INPUT -j PORTSCAN'
ExecStop=/bin/sh -c 'iptables -D INPUT -j PORTSCAN 2>/dev/null || true; iptables -F PORTSCAN 2>/dev/null || true; iptables -X PORTSCAN 2>/dev/null || true'

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable portscan-detect >/dev/null 2>&1
    systemctl start portscan-detect >/dev/null 2>&1 || warn "Не удалось запустить portscan-detect (iptables может быть недоступен)"


    info "Создание конфигурации jail.local..."


   cat > /etc/fail2ban/jail.local << 'EOF'
# ╔════════════════════════════════════════════════════════════════╗
# ║  Remnawave Fail2ban Configuration                              ║
# ╚════════════════════════════════════════════════════════════════╝

[DEFAULT]
# Бан через UFW
banaction = ufw
banaction_allports = ufw
# Игнорировать localhost и приватные сети
ignoreip = 127.0.0.1/8 ::1 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16
# Время бана по умолчанию — 1 час
bantime = 3600
# Окно поиска — 10 минут
findtime = 600
# Количество попыток по умолчанию
maxretry = 5

# ── SSH защита от брутфорса ──────────────────────────────────────
[sshd]
enabled = true
port = 2225
filter = sshd
backend = systemd
maxretry = 5
findtime = 600
bantime = 3600
EOF
    # Добавление portscan jail только если лог-файл существует
    local portscan_log=""
    if [ -f /var/log/kern.log ]; then
        portscan_log="/var/log/kern.log"
    elif [ -f /var/log/syslog ]; then
        portscan_log="/var/log/syslog"
    fi

    if [ -n "$portscan_log" ]; then
        cat >> /etc/fail2ban/jail.local << EOF

# ── Детект порт-сканирования ─────────────────────────────────────
[portscan]
enabled = true
filter = portscan
logpath = $portscan_log
maxretry = 3
findtime = 300
bantime = 86400
EOF
        info "Portscan jail включён (лог: $portscan_log)"
    else
        info "Лог ядра не найден — portscan jail пропущен"
    fi

    success "Конфигурация jail.local создана"

    # Перезапуск fail2ban
    info "Запуск Fail2ban..."
    systemctl enable fail2ban >/dev/null 2>&1
    systemctl restart fail2ban >/dev/null 2>&1

    # Проверка статуса
    sleep 2
    if systemctl is-active --quiet fail2ban; then
        success "Fail2ban запущен"

        echo
        info "Активные jail'ы:"
        fail2ban-client status 2>/dev/null | grep "Jail list" || true
        echo
    else
        warn "Fail2ban не запустился. Проверьте: journalctl -u fail2ban"
    fi

    echo
    echo -e "Конфигурация Fail2ban:${NC}"
    if [ -n "$portscan_log" ]; then
        echo -e " Порт-сканы: maxretry=3, bantime=24ч${NC}"
    fi
    echo -e "Конфиг: /etc/fail2ban/jail.local${NC}"
    echo

    success "Fail2Ban настроен"
}

module_fail2ban_setup