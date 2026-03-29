#!/bin/bash
#===============================================================================
# Download and Run
# Version: 1.0.0
# Usage: curl -fsSL https://raw.githubusercontent.com/FuriousWarrior/FastServerSetup/refs/heads/main/run.sh | bash
#===============================================================================

set -euo pipefail

# Configuration
REPO_URL="${REPO_URL:-https://github.com/FuriousWarrior/FastServerSetup/}"
TEMP_DIR="/tmp/FastServerSetup-$$"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    local level="$1"; shift
    echo -e "${BLUE}[${level}]${NC} $*"
}

info() { log "INFO" "$@"; }
warn() { log "WARN" "$@"; }
error() { log "ERROR" "$@"; }
success() { log "SUCCESS" "$@"; }

cleanup() {
    info "Очистка временных файлов..."
    rm -rf "${TEMP_DIR}"
}

trap cleanup EXIT

info "Загрузка скриптов из репозитория..."
info "URL: ${REPO_URL}"

mkdir -p "${TEMP_DIR}"

# Download main installer
if curl -fsSL "${REPO_URL}/install.sh" -o "${TEMP_DIR}/install.sh" 2>/dev/null; then
    success "install.sh загружен"
    chmod +x "${TEMP_DIR}/install.sh"
else
    error "Не удалось загрузить install.sh"
    exit 1
fi

# Download modular version
if curl -fsSL "${REPO_URL}/main.sh" -o "${TEMP_DIR}/main.sh" 2>/dev/null; then
    success "main.sh загружен"
    chmod +x "${TEMP_DIR}/main.sh"
fi

# Download config
mkdir -p "${TEMP_DIR}/config"
if curl -fsSL "${REPO_URL}/config/settings.conf" -o "${TEMP_DIR}/config/settings.conf" 2>/dev/null; then
    success "settings.conf загружен"
fi

# Download modules
mkdir -p "${TEMP_DIR}/modules"
for i in $(seq -w 1 10); do
    module_file="0${i}-*.sh"
    if curl -fsSL "${REPO_URL}/modules/${i}-system-update.sh" -o "${TEMP_DIR}/modules/${i}-system-update.sh" 2>/dev/null || \
       curl -fsSL "${REPO_URL}/modules/0${i}-system-update.sh" -o "${TEMP_DIR}/modules/0${i}-system-update.sh" 2>/dev/null; then
        success "Модуль ${i} загружен"
        chmod +x "${TEMP_DIR}/modules/"*.sh 2>/dev/null || true
    fi
done

# Run installer
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Загрузка завершена!                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Выберите режим запуска:"
echo "  1) Single-file installer (install.sh)"
echo "  2) Modular version (main.sh)"
echo "  3) Выйти и запустить вручную"
echo ""
read -p "Выбор (1-3): " choice

case $choice in
    1)
        info "Запуск single-file installer..."
        sudo "${TEMP_DIR}/install.sh"
        ;;
    2)
        info "Запуск modular version..."
        cd "${TEMP_DIR}"
        sudo ./main.sh
        ;;
    3)
        info "Файлы доступны в: ${TEMP_DIR}"
        echo "Для запуска выполните:"
        echo "  cd ${TEMP_DIR}"
        echo "  sudo ./install.sh"
        ;;
    *)
        error "Неверный выбор"
        exit 1
        ;;
esac

success "Готово!"