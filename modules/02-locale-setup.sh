#!/bin/bash
#===============================================================================
# Module 02: Locale Setup (RU UTF-8)
#===============================================================================

module_locale_setup() {
    info "Настройка локали..."
    
    # Generate locale
    info "Генерация локали ${LOCALE_LANG}..."
    sed -i "s/# ${LOCALE_LANG}/${LOCALE_LANG}/" /etc/locale.gen
    locale-gen
    
    # Configure dpkg
    info "Настройка dpkg-reconfigure locales..."
    echo "${LOCALE_LANG} ${LOCALE_CHARSET}" > /etc/default/locale
    echo "LANG=${LOCALE_LANG}" >> /etc/default/locale
    echo "LANGUAGE=${LOCALE_LANG}" >> /etc/default/locale
    echo "LC_ALL=${LOCALE_LANG}" >> /etc/default/locale
    
    # Apply settings
    export LANG="${LOCALE_LANG}"
    export LANGUAGE="${LOCALE_LANG}"
    export LC_ALL="${LOCALE_LANG}"
    
    success "Локаль настроена: ${LOCALE_LANG}"
}

module_locale_setup