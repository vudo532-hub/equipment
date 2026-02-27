#!/usr/bin/env bash
# ============================================================
# update.sh — Обновление Equipment Management System
# Запускать от root на целевой машине
# ============================================================
set -euo pipefail

APP_DIR="/opt/equipment"
APP_USER="equipment"
BACKUP_BEFORE_UPDATE=true

echo "============================================"
echo "  Обновление Equipment Management System"
echo "============================================"

# Проверка наличия обновлённых файлов
if [ ! -d "$1" ] 2>/dev/null; then
    echo "Использование: $0 <путь_к_новой_версии>"
    echo "Пример: $0 /tmp/equipment-offline/equipment"
    exit 1
fi
NEW_VERSION_DIR="$1"

# ----- 1. Резервное копирование -----
if [ "$BACKUP_BEFORE_UPDATE" = true ]; then
    echo ""
    echo "[1/5] Резервное копирование..."
    bash "$APP_DIR/deploy/backup.sh"
fi

# ----- 2. Остановка сервисов -----
echo ""
echo "[2/5] Остановка сервисов..."
systemctl stop equipment-queue 2>/dev/null || true
systemctl stop equipment-web 2>/dev/null || true
echo "  ✓ Сервисы остановлены."

# ----- 3. Обновление файлов -----
echo ""
echo "[3/5] Обновление файлов..."
rsync -a \
    --exclude='.env' \
    --exclude='config/master.key' \
    --exclude='config/credentials.yml.enc' \
    --exclude='storage/' \
    --exclude='log/' \
    --exclude='tmp/' \
    --exclude='vendor/bundle/' \
    "$NEW_VERSION_DIR/" "$APP_DIR/"

chown -R "$APP_USER:$APP_USER" "$APP_DIR"
echo "  ✓ Файлы обновлены."

# ----- 4. Установка gem-ов и миграции -----
echo ""
echo "[4/5] Установка gem-ов и миграции..."
su - "$APP_USER" -c "
    export PATH=\"\$HOME/.rbenv/bin:\$PATH\"
    eval \"\$(rbenv init -)\"
    cd $APP_DIR
    set -a; source .env; set +a
    
    bundle config set --local deployment true
    bundle config set --local without 'development test'
    bundle config set --local path vendor/bundle
    bundle install --local 2>/dev/null || bundle install
    
    bin/rails db:migrate
    bin/rails db:migrate:cache 2>/dev/null || true
    bin/rails db:migrate:queue 2>/dev/null || true
    bin/rails db:migrate:cable 2>/dev/null || true
    
    bin/rails assets:precompile
"
echo "  ✓ Зависимости и миграции обновлены."

# ----- 5. Запуск сервисов -----
echo ""
echo "[5/5] Запуск сервисов..."
systemctl daemon-reload
systemctl start equipment-web
systemctl start equipment-queue
echo "  ✓ Сервисы запущены."

echo ""
echo "============================================"
echo "  Обновление завершено!"
echo "============================================"
echo "  Проверьте: systemctl status equipment-web"
