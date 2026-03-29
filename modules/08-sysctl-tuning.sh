#!/bin/bash
#===============================================================================
# Module 08: Sysctl Tuning
#===============================================================================

module_sysctl_tuning() {
    info "Применение сетевых настроек (BBR, TCP tuning, лимиты)..."
     
    # Создание файла конфигурации sysctl
    local sysctl_file="/etc/sysctl.d/99-remnawave-tuning.conf"

    # Проверка поддержки BBR: bbr3 (ядро 6.12+) → bbr2 (XanMod) → bbr (стандартный)
    info "Проверка поддержки BBR..."
    BBR_MODULE=""
    BBR_ALGO=""

    # 1. Пробуем BBR3 (встроен в ядро 6.12+)
    if grep -q "bbr3" /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null; then
        BBR_MODULE="tcp_bbr"
        BBR_ALGO="bbr3"
        success "BBR3 доступен (ядро $(uname -r))"
    # 2. Пробуем BBR2 (XanMod / пропатченные ядра)
    elif grep -q "bbr2" /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null; then
        BBR_MODULE="tcp_bbr2"
        BBR_ALGO="bbr2"
        success "BBR2 доступен (ядро $(uname -r))"
    elif grep -q "tcp_bbr2" /proc/modules 2>/dev/null || modprobe tcp_bbr2 2>/dev/null; then
        BBR_MODULE="tcp_bbr2"
        BBR_ALGO="bbr2"
        success "Модуль BBR2 загружен"
    else
        # BBR2 недоступен — предлагаем установить XanMod ядро
        warn "BBR2/BBR3 недоступны на текущем ядре ($(uname -r)) Установите сначала XanMode"

    log_info "Используется алгоритм: ${BBR_ALGO}"

    # Создание конфигурационного файла
    log_info "Создание конфигурации sysctl..."

    cat > "$sysctl_file" << EOF
# ╔════════════════════════════════════════════════════════════════╗
# ║  Remnawave Network Tuning Configuration                        ║
# ║  Оптимизация сети для VPN/Proxy нод                           ║
# ╚════════════════════════════════════════════════════════════════╝

# === IPv6 (Отключен для стабильности, lo оставлен для совместимости) ===
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 0

# === IPv4 и Маршрутизация ===
net.ipv4.ip_forward = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# === Оптимизация TCP и BBR2 ===
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = ${BBR_ALGO}
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_tw_buckets = 262144
net.ipv4.tcp_max_syn_backlog = 8192
net.core.somaxconn = 8192

# === TCP Keepalive ===
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_fin_timeout = 15

# === Буферы сокетов (16 MB) ===
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# === Безопасность ===
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.tcp_syncookies = 1

# === Системные лимиты ===
fs.file-max = 2097152
vm.swappiness = 10
EOF

    success "Конфигурация sysctl создана: $sysctl_file"

    # Применение настроек
    info "Применение настроек sysctl..."
    if sysctl -p "$sysctl_file" >/dev/null 2>&1; then
        success "Настройки sysctl применены"
    else
        warn "Некоторые настройки могли не примениться (это нормально для некоторых систем)"
        sysctl -p "$sysctl_file" 2>&1 | grep -i "error\|invalid" || true
    fi

    # Настройка лимитов файлов
    info "Настройка лимитов файловых дескрипторов..."

    local limits_file="/etc/security/limits.d/99-remnawave.conf"
    cat > "$limits_file" << 'EOF'
# Remnawave File Limits
* soft nofile 1048576
* hard nofile 1048576
* soft nproc 65535
* hard nproc 65535
root soft nofile 1048576
root hard nofile 1048576
root soft nproc 65535
root hard nproc 65535
EOF

    success "Лимиты файлов настроены: $limits_file"

    # Настройка systemd лимитов
    info "Настройка systemd лимитов..."

    local systemd_conf="/etc/systemd/system.conf.d"
    mkdir -p "$systemd_conf"
    cat > "$systemd_conf/99-remnawave.conf" << 'EOF'
[Manager]
DefaultLimitNOFILE=1048576
DefaultLimitNPROC=65535
EOF

    # Перезагрузка systemd
    systemctl daemon-reexec 2>/dev/null || true

    success "Systemd лимиты настроены"

    # Проверка применённых настроек
    echo
    info "Проверка применённых настроек:"
    echo -e "   BBR: $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo 'не определено')${NC}"
    echo -e "   IP Forward: $(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo 'не определено')${NC}"
    echo -e "   TCP FastOpen: $(sysctl -n net.ipv4.tcp_fastopen 2>/dev/null || echo 'не определено')${NC}"
    echo -e "   File Max: $(sysctl -n fs.file-max 2>/dev/null || echo 'не определено')${NC}"
    echo -e "   Somaxconn: $(sysctl -n net.core.somaxconn 2>/dev/null || echo 'не определено')${NC}"
    echo

    success "Оптимизация сетевых настроек завершена"

    echo -e "Для полного применения лимитов рекомендуется перезагрузка системы${NC}"





}

module_sysctl_tuning