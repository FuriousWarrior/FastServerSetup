# FastServerSetup

# Debian Server Automation Script

## Быстрый старт

```bash
# Скачать
git clone https://github.com/FuriousWarrior/FastServerSetup.git
cd FastServerSetup

# Запустить в интерактивном режиме
sudo ./main.sh

# Запустить все модули автоматически
INTERACTIVE_MODE=false sudo ./main.sh

Конфигурация
Измените config/settings.conf для настройки параметров.

## 🚀 Использование
```bash
# Сделать скрипты исполняемыми
chmod +x main.sh
chmod +x modules/*.sh

# Запуск
sudo ./main.sh
```



Добавление нового модуля

```
Создайте файл modules/XX-module-name.sh
```
Добавьте функцию module_<name>()

Вызовите функцию в конце файла
Модуль автоматически появится в меню

Пример нового модуля

```
#!/bin/bash
module_example() {
    info "Пример модуля"
    # Ваш код
}
module_example
```
