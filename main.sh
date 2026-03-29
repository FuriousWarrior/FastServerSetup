#!/bin/bash
#===============================================================================
# Debian Server Automation Script
# Version: 2.0.2
# Description: Modular server setup and hardening for Debian 13 (Trixie)
#===============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="${SCRIPT_DIR}/modules"
CONFIG_DIR="${SCRIPT_DIR}/config"
LOGS_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOGS_DIR}/setup_$(date +%Y%m%d_%H%M%S).log"

# Load configuration
if [[ -f "${CONFIG_DIR}/settings.conf" ]]; then
    source "${CONFIG_DIR}/settings.conf"
else
    echo -e "${RED}[ERROR] Config file not found: ${CONFIG_DIR}/settings.conf${NC}"
    exit 1
fi

#===============================================================================
# Logging Functions
#===============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

info() { log "INFO" "$@"; }
warn() { log "WARN" "$@"; echo -e "${YELLOW}⚠ $*${NC}"; }
error() { log "ERROR" "$@"; echo -e "${RED}✗ $*${NC}"; }
success() { log "SUCCESS" "$@"; echo -e "${GREEN}✓ $*${NC}"; }

#===============================================================================
# Utility Functions
#===============================================================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Этот скрипт должен быть запущен от root"
        exit 1
    fi
}

check_debian() {
    if [[ ! -f /etc/debian_version ]]; then
        error "Этот скрипт предназначен только для Debian"
        exit 1
    fi
}

create_dirs() {
    mkdir -p "${LOGS_DIR}"
    info "Директории созданы"
}

run_module() {
    local module="$1"
    local module_path="${MODULES_DIR}/${module}"
    
    if [[ -f "${module_path}" ]]; then
        info "Запуск модуля: ${module}"
        # Исполняем модуль (source, чтобы он мог использовать функции и переменные)
        source "${module_path}"
        success "Модуль ${module} выполнен"
    else
        warn "Модуль ${module} не найден"
        return 1
    fi
}

#===============================================================================
# Module Selection
#===============================================================================

show_menu() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   Debian Server Setup Automation${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "Выберите модули для выполнения:"
    echo ""
    echo "  1) Обновление системы (Debian 13)"
    echo "  2) Настройка локали (RU UTF-8)"
    echo "  3) Синхронизация времени"
    echo "  4) Настройка SSH ключа"
    echo "  5) Hardening SSH (порт 2225)"
    echo "  6) Настройка SWAP"
    echo "  7) Настройка UFW"
    echo "  8) Sysctl тюнинг"
    echo "  9) Установка Fail2Ban"
    echo " 10) Внешние скрипты"
    echo " 11) Установка XanMod"
    echo " 111) Выполнить ВСЕ модули"
    echo " 222) Выход"
    echo ""
}

#===============================================================================
# Main Execution
#===============================================================================

main() {
    check_root
    check_debian
    create_dirs
    
    info "Запуск скрипта настройки сервера"
    info "Версия Debian: $(cat /etc/debian_version)"
    info "Версия ядра: $(uname -r)"
    
    # Определяем, интерактивный ли режим
    # Если INTERACTIVE_MODE явно установлен в false или stdin не терминал, то неинтерактивный
    if [[ "${INTERACTIVE_MODE:-auto}" == "false" ]] || [[ ! -t 0 ]]; then
        info "Неинтерактивный режим: выполнение всех модулей"
        for module in $(ls -1 "${MODULES_DIR}"/*.sh 2>/dev/null | sort); do
            run_module "$(basename "${module}")"
        done
    else
        show_menu
        
        # Чтение ввода из терминала (даже если stdin перенаправлен)
        local choice=""
        while true; do
            # Пытаемся читать из /dev/tty, если он доступен
            if [[ -e /dev/tty ]]; then
                read -p "Выберите номер (1-11, 111, 222): " choice < /dev/tty
            else
                # fallback на обычный stdin
                read -p "Выберите номер (1-11, 111, 222): " choice
            fi
            
            case "$choice" in
                1|2|3|4|5|6|7|8|9|10|11|111|222)
                    break
                    ;;
                *)
                    echo -e "${RED}Неверный выбор. Пожалуйста, введите номер из списка.${NC}"
                    ;;
            esac
        done
        
        case $choice in
            1) run_module "01-system-update.sh" ;;
            2) run_module "02-locale-setup.sh" ;;
            3) run_module "03-time-sync.sh" ;;
            4) run_module "04-ssh-key.sh" ;;
            5) run_module "05-ssh-hardening.sh" ;;
            6) run_module "06-swap-setup.sh" ;;
            7) run_module "07-ufw-setup.sh" ;;
            8) run_module "08-sysctl-tuning.sh" ;;
            9) run_module "09-fail2ban-setup.sh" ;;
            10) run_module "10-external-scripts.sh" ;;
            11) run_module "11-xanmod.sh" ;;
            111)
                info "Запуск всех модулей..."
                for module in $(ls -1 "${MODULES_DIR}"/*.sh 2>/dev/null | sort); do
                    run_module "$(basename "${module}")"
                done
                ;;
            222)
                info "Выход по запросу пользователя"
                exit 0
                ;;
        esac
    fi
    
    success "Настройка сервера завершена!"
    info "Лог сохранен: ${LOG_FILE}"
}

# Run main function
main "$@"