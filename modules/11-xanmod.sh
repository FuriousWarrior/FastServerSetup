#!/bin/bash
#===============================================================================
# Установка XanMod
#===============================================================================

module_xanmod () {
    info "XanMod доступен только для x86_64, Установка XanMod..."
        # Только для Debian/Ubuntu x86_64
    local arch
    arch=$(uname -m)
    if [ "$arch" != "x86_64" ]; then
        error "XanMod доступен только для x86_64 (текущая: $arch)"
        return 1
    fi

    # Проверка совместимости процессора (уровень ISA)
    local xanmod_level=""
    if grep -q "v4" /proc/cpuinfo 2>/dev/null && grep -q "avx512" /proc/cpuinfo 2>/dev/null; then
        xanmod_level="x64v4"
    elif grep -q "avx2" /proc/cpuinfo 2>/dev/null; then
        xanmod_level="x64v3"
    elif grep -q "sse4_2" /proc/cpuinfo 2>/dev/null; then
        xanmod_level="x64v2"
    else
        xanmod_level="x64v1"
    fi
    info "Уровень ISA процессора: $xanmod_level"

    # Добавление репозитория XanMod
    info "Добавление репозитория XanMod..."

    local xanmod_key="/usr/share/keyrings/xanmod-archive-keyring.gpg"
    if ! curl -fsSL https://dl.xanmod.org/archive.key 2>/dev/null | gpg --dearmor -o "$xanmod_key" 2>/dev/null; then
        error "Не удалось добавить GPG ключ XanMod"
        return 1
    fi

    echo "deb [signed-by=$xanmod_key] http://deb.xanmod.org releases main" > /etc/apt/sources.list.d/xanmod-release.list

    # Обновление списка пакетов
    apt-get update -qq >/dev/null 2>&1 || true

    # Установка ядра XanMod MAIN (стабильная ветка с BBR2)
    local kernel_pkg="linux-xanmod-${xanmod_level}"
    info "Установка пакета: $kernel_pkg..."

    if apt-get install -y -qq "$kernel_pkg" >/dev/null 2>&1; then
        success "XanMod ядро ($xanmod_level) установлено"
        warn "Для активации BBR2 необходима перезагрузка сервера!"
        return 0
    else
        error "Не удалось установить $kernel_pkg"
        # Очистка
        rm -f "$xanmod_key" /etc/apt/sources.list.d/xanmod-release.list
        apt-get update -qq >/dev/null 2>&1 || true
        return 1
    fi

}

module_xanmod