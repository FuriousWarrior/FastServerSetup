#!/bin/bash
#===============================================================================
# Debian Server Automation Script
# Version: 2.0.1
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
source "${CONFIG_DIR}/settings.conf"

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
    echo " 11) Установка XanMode"
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
    
    if [[ "${INTERACTIVE_MODE:-true}" == "true" ]]; then
        show_menu
        read -p "Выберите номер (1-12): " choice
        
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
                for module in $(ls -1 "${MODULES_DIR}"/*.sh | sort); do
                    run_module "$(basename ${module})"
                done
                ;;
            222) 
                info "Выход"
                exit 0
                ;;
            *) 
                error "Неверный выбор"
                exit 1
                ;;
        esac
    else
        # Non-interactive mode - run all modules
        for module in $(ls -1 "${MODULES_DIR}"/*.sh | sort); do
            run_module "$(basename ${module})"
        done
    fi
    
    success "Настройка сервера завершена!"
    info "Лог сохранен: ${LOG_FILE}"
}

# Run main function
main "$@"