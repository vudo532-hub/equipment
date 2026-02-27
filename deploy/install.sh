#!/usr/bin/env bash
# ============================================================
# install.sh — Установка Equipment Management System на сервер
# Запускать от root на целевой машине (Ubuntu/Debian)
# ============================================================
set -euo pipefail

APP_DIR="/opt/equipment"
APP_USER="equipment"
RUBY_VERSION="3.4.1"

echo "============================================"
echo "  Установка Equipment Management System"
echo "============================================"

# ----- 1. Системные пакеты (должны быть предустановлены или скопированы) -----
echo ""
echo "[1/9] Проверка системных зависимостей..."
for cmd in gcc make git curl libpq-dev postgresql nginx; do
    if ! command -v "$cmd" &>/dev/null && ! dpkg -s "$cmd" &>/dev/null 2>&1; then
        echo "  ⚠ Пакет '$cmd' не найден."
        echo "    Для оффлайн-установки скопируйте .deb пакеты и установите через: dpkg -i *.deb"
        echo "    Или установите онлайн: apt-get install -y build-essential libpq-dev postgresql postgresql-contrib nginx libffi-dev libssl-dev libyaml-dev zlib1g-dev"
    else
        echo "  ✓ $cmd"
    fi
done

# ----- 2. Создание пользователя -----
echo ""
echo "[2/9] Создание системного пользователя '$APP_USER'..."
if id "$APP_USER" &>/dev/null; then
    echo "  Пользователь уже существует."
else
    useradd --system --create-home --shell /bin/bash "$APP_USER"
    echo "  ✓ Пользователь создан."
fi

# ----- 3. Установка Ruby через rbenv -----
echo ""
echo "[3/9] Проверка Ruby $RUBY_VERSION..."
if su - "$APP_USER" -c "ruby --version 2>/dev/null | grep -q '$RUBY_VERSION'"; then
    echo "  ✓ Ruby $RUBY_VERSION уже установлен."
else
    echo "  Устанавливаем Ruby $RUBY_VERSION через rbenv..."
    echo "  ВАЖНО: Для оффлайн-установки Ruby:"
    echo "    1. Скопируйте архив ruby-$RUBY_VERSION.tar.bz2 в ~/.rbenv/cache/"
    echo "    2. Или установите Ruby заранее из предварительно собранного пакета"
    echo ""
    echo "  Если есть интернет, rbenv install автоматически загрузит Ruby."
    
    # Установка rbenv (если ещё нет)
    if [ ! -d "/home/$APP_USER/.rbenv" ]; then
        su - "$APP_USER" -c '
            git clone https://github.com/rbenv/rbenv.git ~/.rbenv 2>/dev/null || true
            git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build 2>/dev/null || true
            echo "export PATH=\"\$HOME/.rbenv/bin:\$PATH\"" >> ~/.bashrc
            echo "eval \"\$(rbenv init -)\"" >> ~/.bashrc
        '
    fi
    
    su - "$APP_USER" -c "
        export PATH=\"\$HOME/.rbenv/bin:\$PATH\"
        eval \"\$(rbenv init -)\"
        rbenv install $RUBY_VERSION --skip-existing
        rbenv global $RUBY_VERSION
        gem install bundler --no-document
    "
    echo "  ✓ Ruby $RUBY_VERSION установлен."
fi

# ----- 4. Копирование приложения -----
echo ""
echo "[4/9] Копирование приложения в $APP_DIR..."
if [ ! -d "$APP_DIR" ]; then
    mkdir -p "$APP_DIR"
fi

# Если скрипт запущен из директории проекта
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [ -f "$PROJECT_DIR/Gemfile" ]; then
    rsync -a --exclude='.git' --exclude='node_modules' --exclude='tmp/*' \
          --exclude='log/*' --exclude='storage/*' --exclude='coverage' \
          "$PROJECT_DIR/" "$APP_DIR/"
    echo "  ✓ Файлы скопированы."
else
    echo "  ⚠ Запустите скрипт из директории deploy/ проекта,"
    echo "    или скопируйте файлы вручную в $APP_DIR"
fi

chown -R "$APP_USER:$APP_USER" "$APP_DIR"
mkdir -p "$APP_DIR"/{log,tmp/pids,tmp/cache,tmp/sockets,storage}
chown -R "$APP_USER:$APP_USER" "$APP_DIR"

# ----- 5. Установка gem-ов из кэша (оффлайн) -----
echo ""
echo "[5/9] Установка Ruby gem-ов..."
su - "$APP_USER" -c "
    export PATH=\"\$HOME/.rbenv/bin:\$PATH\"
    eval \"\$(rbenv init -)\"
    cd $APP_DIR
    bundle config set --local deployment true
    bundle config set --local without 'development test'
    bundle config set --local path vendor/bundle
    bundle install --local 2>/dev/null || bundle install
"
echo "  ✓ Gem-ы установлены."

# ----- 6. База данных PostgreSQL -----
echo ""
echo "[6/9] Настройка PostgreSQL..."
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='equipment'" | grep -q 1; then
    echo "  Роль 'equipment' уже существует."
else
    DB_PASSWORD=$(openssl rand -hex 16)
    sudo -u postgres psql -c "CREATE ROLE equipment WITH LOGIN PASSWORD '$DB_PASSWORD' CREATEDB;"
    echo "  ✓ Роль PostgreSQL создана. Пароль: $DB_PASSWORD"
    echo "  ⚠ СОХРАНИТЕ ПАРОЛЬ! Он нужен для переменной EQUIPMENT_DATABASE_PASSWORD"
fi

sudo -u postgres psql -c "CREATE DATABASE equipment_production OWNER equipment;" 2>/dev/null || echo "  База данных уже существует."
sudo -u postgres psql -c "CREATE DATABASE equipment_production_cache OWNER equipment;" 2>/dev/null || echo "  Cache DB уже существует."
sudo -u postgres psql -c "CREATE DATABASE equipment_production_queue OWNER equipment;" 2>/dev/null || echo "  Queue DB уже существует."
sudo -u postgres psql -c "CREATE DATABASE equipment_production_cable OWNER equipment;" 2>/dev/null || echo "  Cable DB уже существует."

# ----- 7. Генерация SECRET_KEY_BASE и настройка окружения -----
echo ""
echo "[7/9] Настройка окружения..."
SECRET_KEY=$(openssl rand -hex 64)

if [ ! -f "$APP_DIR/.env" ]; then
    cat > "$APP_DIR/.env" << EOF
RAILS_ENV=production
SECRET_KEY_BASE=$SECRET_KEY
EQUIPMENT_DATABASE_PASSWORD=REPLACE_ME
DATABASE_HOST=localhost
DATABASE_PORT=5432
PORT=3000
WEB_CONCURRENCY=2
RAILS_MAX_THREADS=5
FORCE_SSL=false
ASSUME_SSL=false
RAILS_LOG_TO_STDOUT=true

# LDAP (раскомментируйте и настройте)
# LDAP_HOST=ldap.example.com
# LDAP_PORT=389
# LDAP_BASE=dc=example,dc=com
# LDAP_BIND_DN=cn=admin,dc=example,dc=com
# LDAP_BIND_PASSWORD=password

# SMTP (раскомментируйте и настройте)
# SMTP_HOST=mail.example.com
# SMTP_PORT=587
# SMTP_DOMAIN=example.com
# SMTP_USER=equipment@example.com
# SMTP_PASSWORD=password
# APP_HOST=equipment.example.com
EOF
    echo "  ✓ Файл .env создан. ОБЯЗАТЕЛЬНО заполните пароль БД!"
    echo "  SECRET_KEY_BASE сгенерирован автоматически."
else
    echo "  Файл .env уже существует."
fi

# ----- 8. Миграции и подготовка -----
echo ""
echo "[8/9] Подготовка базы данных и ассетов..."
su - "$APP_USER" -c "
    export PATH=\"\$HOME/.rbenv/bin:\$PATH\"
    eval \"\$(rbenv init -)\"
    cd $APP_DIR
    
    # Загрузка переменных окружения
    set -a; source .env; set +a
    
    # Миграции
    bin/rails db:migrate 2>/dev/null || bin/rails db:setup
    
    # Дополнительные БД
    bin/rails db:migrate:cache 2>/dev/null || true
    bin/rails db:migrate:queue 2>/dev/null || true
    bin/rails db:migrate:cable 2>/dev/null || true
    
    # Прекомпиляция ассетов
    bin/rails assets:precompile
    
    # Seed данные (типы оборудования и т.д.)
    bin/rails db:seed
"
echo "  ✓ База данных и ассеты подготовлены."

# ----- 9. Systemd сервисы -----
echo ""
echo "[9/9] Установка systemd сервисов..."
cp "$APP_DIR/deploy/equipment-web.service" /etc/systemd/system/
cp "$APP_DIR/deploy/equipment-queue.service" /etc/systemd/system/

# Обновление переменных окружения в сервисах
if [ -f "$APP_DIR/.env" ]; then
    source "$APP_DIR/.env"
    sed -i "s|SECRET_KEY_BASE=REPLACE_ME_WITH_GENERATED_SECRET|SECRET_KEY_BASE=$SECRET_KEY_BASE|g" /etc/systemd/system/equipment-web.service
    sed -i "s|SECRET_KEY_BASE=REPLACE_ME_WITH_GENERATED_SECRET|SECRET_KEY_BASE=$SECRET_KEY_BASE|g" /etc/systemd/system/equipment-queue.service
    sed -i "s|EQUIPMENT_DATABASE_PASSWORD=REPLACE_ME|EQUIPMENT_DATABASE_PASSWORD=$EQUIPMENT_DATABASE_PASSWORD|g" /etc/systemd/system/equipment-web.service
    sed -i "s|EQUIPMENT_DATABASE_PASSWORD=REPLACE_ME|EQUIPMENT_DATABASE_PASSWORD=$EQUIPMENT_DATABASE_PASSWORD|g" /etc/systemd/system/equipment-queue.service
fi

# Nginx
cp "$APP_DIR/deploy/nginx-equipment.conf" /etc/nginx/sites-available/equipment
ln -sf /etc/nginx/sites-available/equipment /etc/nginx/sites-enabled/equipment
rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

# Перезагрузка конфигов
systemctl daemon-reload
systemctl enable equipment-web equipment-queue
nginx -t && systemctl reload nginx

echo ""
echo "============================================"
echo "  Установка завершена!"
echo "============================================"
echo ""
echo "Запуск:"
echo "  systemctl start equipment-web"
echo "  systemctl start equipment-queue"
echo ""
echo "Логи:"
echo "  journalctl -u equipment-web -f"
echo "  journalctl -u equipment-queue -f"
echo ""
echo "⚠ Не забудьте:"
echo "  1. Отредактировать /opt/equipment/.env (пароли, LDAP, SMTP)"
echo "  2. Обновить systemd сервисы после изменения .env:"
echo "     systemctl daemon-reload && systemctl restart equipment-web"
echo "  3. Создать администратора:"
echo "     cd /opt/equipment && RAILS_ENV=production bundle exec rails console"
echo "     > User.create!(email: 'admin@example.com', login: 'admin', password: 'password', role: :admin, first_name: 'Admin', last_name: 'System')"
echo "============================================"
