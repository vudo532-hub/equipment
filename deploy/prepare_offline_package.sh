#!/usr/bin/env bash
# ============================================================
# prepare_offline_package.sh — Сборка оффлайн-пакета для деплоя
# Запускать на МАШИНЕ С ИНТЕРНЕТОМ (разработческая машина)
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="${1:-/tmp/equipment-offline}"
PACKAGE_NAME="equipment-offline-$(date +%Y%m%d).tar.gz"

echo "============================================"
echo "  Сборка оффлайн-пакета"
echo "  Проект: $PROJECT_DIR"
echo "  Выход:  $OUTPUT_DIR"
echo "============================================"

# ----- 1. Обновление gem-кэша -----
echo ""
echo "[1/5] Кэширование gem-ов..."
cd "$PROJECT_DIR"
bundle cache
echo "  ✓ $(ls vendor/cache/*.gem 2>/dev/null | wc -l) gem-ов в кэше."

# ----- 2. Создание временной директории -----
echo ""
echo "[2/5] Подготовка файлов..."
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Копируем проект, исключая ненужное
rsync -a \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='tmp/*' \
    --exclude='log/*' \
    --exclude='storage/*' \
    --exclude='coverage' \
    --exclude='.bundle' \
    --exclude='vendor/bundle' \
    "$PROJECT_DIR/" "$OUTPUT_DIR/equipment/"

echo "  ✓ Файлы скопированы."

# ----- 3. Прекомпиляция ассетов -----
echo ""
echo "[3/5] Прекомпиляция ассетов..."
cd "$PROJECT_DIR"
RAILS_ENV=production SECRET_KEY_BASE=temporary_key_for_assets bundle exec rails assets:precompile 2>/dev/null || {
    echo "  ⚠ Не удалось прекомпилировать ассеты. Они будут собраны при установке."
}

# Копируем скомпилированные ассеты
if [ -d "$PROJECT_DIR/public/assets" ]; then
    cp -r "$PROJECT_DIR/public/assets" "$OUTPUT_DIR/equipment/public/"
    echo "  ✓ Ассеты скопированы."
fi

# ----- 4. Системные пакеты (список для apt) -----
echo ""
echo "[4/5] Генерация списка зависимостей..."
cat > "$OUTPUT_DIR/SYSTEM_PACKAGES.txt" << 'EOF'
# Необходимые системные пакеты (Ubuntu 22.04 / Debian 12)
# Установите через: apt-get install <package>
#
# Или загрузите .deb пакеты заранее:
#   apt-get download <package> && apt-get download $(apt-cache depends <package> | grep Depends | cut -d: -f2)

build-essential
libpq-dev
postgresql
postgresql-contrib
nginx
libffi-dev
libssl-dev
libyaml-dev
zlib1g-dev
libreadline-dev
autoconf
bison
rustc  # Для некоторых gem-ов с нативными расширениями

# Для rbenv/ruby-build
git
curl
EOF

echo "  ✓ Список зависимостей создан."

# ----- 5. Создание архива -----
echo ""
echo "[5/5] Создание архива..."
cd "$(dirname "$OUTPUT_DIR")"
tar -czf "$PACKAGE_NAME" "$(basename "$OUTPUT_DIR")"
ARCHIVE_PATH="$(pwd)/$PACKAGE_NAME"
echo "  ✓ Архив создан: $ARCHIVE_PATH"
echo "  Размер: $(du -h "$ARCHIVE_PATH" | cut -f1)"

echo ""
echo "============================================"
echo "  Готово!"
echo "============================================"
echo ""
echo "Для установки на целевой сервер:"
echo "  1. Скопируйте $ARCHIVE_PATH на сервер"
echo "  2. tar -xzf $PACKAGE_NAME"
echo "  3. cd equipment-offline/equipment"
echo "  4. sudo bash deploy/install.sh"
echo ""
echo "Подробная инструкция: docs/DEPLOYMENT.md"
echo "============================================"
