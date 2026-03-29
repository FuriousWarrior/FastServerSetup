#!/bin/bash
#===============================================================================
# Download and Run (Git Clone Version)
# Version: 2.0.1
# Usage: curl -fsSL https://raw.githubusercontent.com/FuriousWarrior/FastServerSetup/refs/heads/main/run.sh | bash
#===============================================================================

set -euo pipefail

# Configuration
REPO_GIT_URL="${REPO_GIT_URL:-https://github.com/FuriousWarrior/FastServerSetup.git}"
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

# Проверка наличия git
if ! command -v git &> /dev/null; then
    error "Git не установлен. Пожалуйста, установите git и запустите скрипт снова."
    exit 1
fi

info "Клонирование репозитория из ${REPO_GIT_URL}..."
mkdir -p "${TEMP_DIR}"

# Отключаем интерактивные запросы git (например, запрос пароля/ключа)
export GIT_TERMINAL_PROMPT=0

if git clone --depth 1 "${REPO_GIT_URL}" "${TEMP_DIR}" 2>&1; then
    success "Репозиторий успешно склонирован в ${TEMP_DIR}"
else
    error "Не удалось клонировать репозиторий. Проверьте URL и сетевое соединение."
    exit 1
fi

# Удаляем .git, так как это временная копия
rm -rf "${TEMP_DIR}/.git"

# Устанавливаем права на выполнение для скриптов
chmod +x "${TEMP_DIR}/install.sh" 2>/dev/null || true
chmod +x "${TEMP_DIR}/main.sh" 2>/dev/null || true
chmod +x "${TEMP_DIR}/modules/"*.sh 2>/dev/null || true

# Проверка наличия основного установщика
if [ ! -f "${TEMP_DIR}/install.sh" ] && [ ! -f "${TEMP_DIR}/main.sh" ]; then
    error "В репозитории не найдены ни install.sh, ни main.sh"
    exit 1
fi

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

while true; do
    read -p "Выбор (1-3): " choice
    case "$choice" in
        1|2|3) break ;;
        *) echo -e "${RED}Неверный выбор. Пожалуйста, введите 1, 2 или 3.${NC}" ;;
    esac
done

case $choice in
    1)
        if [ ! -f "${TEMP_DIR}/install.sh" ]; then
            error "Файл install.sh не найден в репозитории"
            exit 1
        fi
        info "Запуск single-file installer..."
        sudo "${TEMP_DIR}/install.sh"
        ;;
    2)
        if [ ! -f "${TEMP_DIR}/main.sh" ]; then
            error "Файл main.sh не найден в репозитории"
            exit 1
        fi
        info "Запуск modular version..."
        cd "${TEMP_DIR}" || { error "Не удалось перейти в ${TEMP_DIR}"; exit 1; }
        sudo ./main.sh
        ;;
    3)
        info "Файлы доступны в: ${TEMP_DIR}"
        echo "Для запуска выполните:"
        echo "  cd ${TEMP_DIR}"
        echo "  sudo ./install.sh"
        ;;
esac

success "Готово!"