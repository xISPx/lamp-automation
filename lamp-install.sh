#!/bin/bash

# =============================================
# Автоматическая установка LAMP-стека на Ubuntu
# Версия: 4.2
# Автор: Ваше Имя
# Лицензия: MIT
# =============================================

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Сброс цветов

# Проверка прав root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}ОШИБКА: Скрипт должен быть запущен с правами root${NC}"
  exit 1
fi

# Генерация пароля MySQL
generate_mysql_password() {
  openssl rand -base64 16 | sed 's/[+/=]//g' | head -c 16
}

# Инициализация переменных
MYSQL_ROOT_PASSWORD=$(generate_mysql_password)
LOG_FILE="/var/log/lamp_install_$(date +%Y%m%d%H%M%S).log"

# Настройка логирования
exec > >(tee -a "$LOG_FILE")
exec 2>&1

# Заголовок установки
echo -e "${YELLOW}"
echo "========================================"
echo " Начало установки LAMP-стека"
echo " Лог-файл: $LOG_FILE"
echo "========================================"
echo -e "${NC}"

# Обновление системы
echo -e "\n${GREEN}[1/8] Обновление пакетов...${NC}"
apt-get update && apt-get upgrade -y

# Установка Apache
echo -e "\n${GREEN}[2/8] Установка Apache...${NC}"
apt-get install -y apache2
systemctl enable --now apache2

# Создание веб-директории
if [ ! -d "/var/www/html" ]; then
  mkdir -p /var/www/html
fi

# Установка MySQL
echo -e "\n${GREEN}[3/8] Установка MySQL...${NC}"
apt-get install -y mysql-server
systemctl enable --now mysql

# Настройка безопасности MySQL
echo -e "\n${GREEN}[4/8] Настройка MySQL...${NC}"

# Проверка подключения к MySQL
echo -e "${YELLOW}Проверка подключения к MySQL...${NC}"
if ! mysqladmin -u root -p"$MYSQL_ROOT_PASSWORD" ping > /dev/null 2>&1; then
  echo -e "${RED}ОШИБКА: Не удалось подключиться к MySQL с root-паролем. Попытка установить пароль...${NC}"
  # Установка пароля root
  mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';" || {
    echo -e "${RED}ОШИБКА: Не удалось установить пароль root для MySQL. Пожалуйста, проверьте вручную.${NC}"
    exit 1
  }
fi

# Выполнение команд настройки MySQL
echo -e "${YELLOW}Настройка безопасности MySQL...${NC}"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "DELETE FROM mysql.user WHERE User='';" || {
  echo -e "${RED}ОШИБКА: Не удалось удалить анонимных пользователей.${NC}"
  exit 1
}
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" || {
  echo -e "${RED}ОШИБКА: Не удалось удалить удаленные root-пользователей.${NC}"
  exit 1
}
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS test;" || {
  echo -e "${RED}ОШИБКА: Не удалось удалить тестовую базу данных.${NC}"
  exit 1
}
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;" || {
  echo -e "${RED}ОШИБКА: Не удалось обновить привилегии.${NC}"
  exit 1
}
echo -e "${GREEN}Настройка MySQL завершена успешно.${NC}"

# Установка PHP
echo -e "\n${GREEN}[5/8] Установка PHP...${NC}"
apt-get install -y php libapache2-mod-php \
php-mysql php-cli php-curl php-gd \
php-mbstring php-xml php-zip \
php-opcache php-intl

# Настройка Apache
echo -e "\n${GREEN}[6/8] Настройка Apache...${NC}"
cat > /etc/apache2/mods-enabled/dir.conf <<EOF
<IfModule mod_dir.c>
    DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
</IfModule>
EOF

# Создание тестовой страницы
echo -e "\n${GREEN}[7/8] Создание тестовой страницы...${NC}"
echo "<?php phpinfo(); ?>" > /var/www/html/info.php
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

# Перезапуск Apache
systemctl restart apache2

# Настройка фаервола
echo -e "\n${GREEN}[8/8] Настройка фаервола...${NC}"
ufw allow "Apache Full"
ufw --force enable

# Очистка
echo -e "\n${YELLOW}Очистка системы...${NC}"
apt-get autoremove -y
apt-get clean

# Итоговая информация
echo -e "\n${GREEN}========================================"
echo " Установка успешно завершена!"
echo "========================================"
echo -e "${YELLOW}Данные для доступа:${NC}"
echo -e " MySQL Root пароль: ${RED}${MYSQL_ROOT_PASSWORD}${NC}"
echo -e " Тестовая страница PHP: ${GREEN}http://$(curl -s icanhazip.com)/info.php${NC}"
echo -e "\n${YELLOW}Рекомендуемые действия:${NC}"
echo " 1. Удалить тестовую страницу: rm /var/www/html/info.php"
echo " 2. Настроить виртуальные хосты"
echo " 3. Выполнить mysql_secure_installation"
echo " 4. Настроить бэкапы"
echo -e "\nЛог установки: ${GREEN}${LOG_FILE}${NC}"