# Установка LAMP-стека на Ubuntu

**Скрипт**: `lamp-install.sh` 

**Описание**: Автоматизирует установку LAMP (Linux, Apache, MySQL, PHP) на Ubuntu. Устанавливает Apache, MySQL, PHP 8.3 с модулями, настраивает безопасность MySQL, создает тестовую PHP-страницу и открывает порты в фаерволе.\
**Лицензия**: MIT

## Зависимости

- Ubuntu (тестировалось на 24.04)
- Пакеты: `apache2`, `mysql-server`, `php`, `libapache2-mod-php`, `php-mysql`, `php-cli`, `php-curl`, `php-gd`, `php-mbstring`, `php-xml`, `php-zip`, `php-opcache`, `php-intl`, `ufw`, `curl`, `openssl`
- Права root

## Установка

1. Скачайте скрипт:

   ```bash
   wget https://github.com/xISPx/lamp-automation/releases/download/lamp/lamp-install.sh
   ```
2. Сделайте исполняемым:

   ```bash
   chmod +x lamp-install.sh
   ```
3. Запустите с root:

   ```bash
   sudo ./lamp-install.sh
   ```
4. Проверьте:
   - Лог: `/var/log/lamp_install_YYYYMMDDHHMMSS.log`
   - MySQL: `mysql -u root -p` (пароль в логе) удалите лог после завершения установки
   - PHP: откройте `http://<IP>/info.php`

## Основные шаги скрипта

1. Обновление системы
2. Установка и запуск Apache
3. Установка и запуск MySQL
4. Настройка MySQL (пароль, удаление анонимных пользователей, тестовой БД)
5. Установка PHP и модулей
6. Настройка Apache для PHP
7. Создание `/var/www/html/info.php`
8. Настройка фаервола (`ufw`)
