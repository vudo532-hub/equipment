#!/usr/bin/env bash
# ============================================================
# backup.sh — Резервное копирование Equipment Management System
# Запускать от пользователя equipment или root
# ============================================================
set -euo pipefail

APP_DIR="/opt/equipment"
BACKUP_DIR="/opt/equipment/backups"
DATE=$(date +%Y%m%d_%H%M%S)
KEEP_DAYS=30

echo "=== Резервное копирование Equipment ==="
echo "Дата: $(date)"

mkdir -p "$BACKUP_DIR"

# ----- 1. Дамп базы данных -----
echo "[1/3] Дамп PostgreSQL..."
if [ -f "$APP_DIR/.env" ]; then
    source "$APP_DIR/.env"
fi

DB_NAME="${DATABASE_NAME:-equipment_production}"
DB_HOST="${DATABASE_HOST:-localhost}"
DB_PORT="${DATABASE_PORT:-5432}"
DB_USER="${DATABASE_USER:-equipment}"

PGPASSWORD="${EQUIPMENT_DATABASE_PASSWORD:-}" pg_dump \
    -h "$DB_HOST" \
    -p "$DB_PORT" \
    -U "$DB_USER" \
    -Fc \
    "$DB_NAME" > "$BACKUP_DIR/db_${DATE}.dump"

echo "  ✓ Дамп БД: $BACKUP_DIR/db_${DATE}.dump"

# ----- 2. Резервная копия хранилища (Active Storage) -----
echo "[2/3] Резервная копия файлов..."
if [ -d "$APP_DIR/storage" ] && [ "$(ls -A $APP_DIR/storage 2>/dev/null)" ]; then
    tar -czf "$BACKUP_DIR/storage_${DATE}.tar.gz" -C "$APP_DIR" storage/
    echo "  ✓ Файлы: $BACKUP_DIR/storage_${DATE}.tar.gz"
else
    echo "  — Нет файлов для копирования."
fi

# ----- 3. Резервная копия конфигурации -----
echo "[3/3] Резервная копия конфигурации..."
tar -czf "$BACKUP_DIR/config_${DATE}.tar.gz" \
    -C "$APP_DIR" \
    .env \
    config/database.yml \
    config/credentials.yml.enc \
    config/master.key \
    2>/dev/null || true
echo "  ✓ Конфигурация: $BACKUP_DIR/config_${DATE}.tar.gz"

# ----- Очистка старых бэкапов -----
echo ""
echo "Очистка бэкапов старше $KEEP_DAYS дней..."
find "$BACKUP_DIR" -name "*.dump" -mtime +"$KEEP_DAYS" -delete
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +"$KEEP_DAYS" -delete
echo "  ✓ Очистка завершена."

echo ""
echo "=== Резервное копирование завершено ==="
echo "Расположение: $BACKUP_DIR"
ls -lh "$BACKUP_DIR"/*_${DATE}* 2>/dev/null || true
