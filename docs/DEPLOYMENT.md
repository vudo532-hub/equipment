# Развёртывание Equipment Management System

Руководство по установке на Linux-сервер (VM) **без доступа в интернет**.

---

## Оглавление

1. [Требования к серверу](#1-требования-к-серверу)
2. [Подготовка оффлайн-пакета](#2-подготовка-оффлайн-пакета)
3. [Подготовка сервера](#3-подготовка-сервера)
4. [Установка приложения](#4-установка-приложения)
5. [Настройка PostgreSQL](#5-настройка-postgresql)
6. [Настройка переменных окружения](#6-настройка-переменных-окружения)
7. [Запуск и проверка](#7-запуск-и-проверка)
8. [Настройка Nginx](#8-настройка-nginx)
9. [Настройка LDAP](#9-настройка-ldap)
10. [Настройка почты (SMTP)](#10-настройка-почты-smtp)
11. [Обновление](#11-обновление)
12. [Резервное копирование](#12-резервное-копирование)
13. [Мониторинг и диагностика](#13-мониторинг-и-диагностика)
14. [Решение проблем](#14-решение-проблем)

---

## 1. Требования к серверу

| Параметр      | Минимум | Рекомендуется |
|--------------|---------|---------------|
| ОС           | Ubuntu 22.04 / Debian 12 | Ubuntu 24.04 LTS |
| CPU          | 2 ядра  | 4 ядра        |
| RAM          | 2 GB    | 4 GB          |
| Диск         | 10 GB   | 20+ GB        |
| PostgreSQL   | 14+     | 16            |
| Ruby         | 3.4.1   | 3.4.1         |

### Системные пакеты

```bash
# Если есть интернет:
apt-get update
apt-get install -y build-essential libpq-dev postgresql postgresql-contrib \
  nginx libffi-dev libssl-dev libyaml-dev zlib1g-dev libreadline-dev \
  autoconf bison git curl
```

> **Оффлайн:** Загрузите `.deb` пакеты заранее на машине с интернетом:
> ```bash
> mkdir -p /tmp/debs
> cd /tmp/debs
> apt-get download build-essential libpq-dev postgresql postgresql-contrib nginx \
>   libffi-dev libssl-dev libyaml-dev zlib1g-dev libreadline-dev
> # Скопируйте /tmp/debs на целевой сервер
> dpkg -i *.deb
> ```

---

## 2. Подготовка оффлайн-пакета

На **машине с интернетом** (разработческая машина):

```bash
# Вариант 1: Автоматическая сборка
cd /path/to/equipment
bash deploy/prepare_offline_package.sh /tmp/equipment-offline

# Результат: /tmp/equipment-offline-YYYYMMDD.tar.gz
```

```bash
# Вариант 2: Ручная сборка
cd /path/to/equipment

# 1. Кэшируем все gem-ы
bundle cache

# 2. Проверяем vendor/cache
ls vendor/cache/*.gem | wc -l  # Должно быть ~158 gem-ов

# 3. Прекомпилируем ассеты
RAILS_ENV=production SECRET_KEY_BASE=temp bundle exec rails assets:precompile

# 4. Создаём архив
tar -czf equipment-offline.tar.gz \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='tmp/*' \
  --exclude='log/*' \
  --exclude='storage/*' \
  --exclude='coverage' \
  --exclude='.bundle' \
  --exclude='vendor/bundle' \
  .
```

Скопируйте архив на целевой сервер (USB, SCP, etc.):
```bash
scp equipment-offline.tar.gz user@server:/tmp/
```

---

## 3. Подготовка сервера

### 3.1 Создание пользователя

```bash
sudo useradd --system --create-home --shell /bin/bash equipment
```

### 3.2 Установка Ruby 3.4.1

**С интернетом (через rbenv):**
```bash
sudo -u equipment -i
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc
rbenv install 3.4.1
rbenv global 3.4.1
gem install bundler --no-document
```

**Без интернета:**

Вариант A — скопируйте уже собранный Ruby:
```bash
# На машине-источнике:
tar -czf ruby-3.4.1-compiled.tar.gz -C /home/equipment/.rbenv/versions 3.4.1

# На целевом сервере:
mkdir -p /home/equipment/.rbenv/versions
tar -xzf ruby-3.4.1-compiled.tar.gz -C /home/equipment/.rbenv/versions/
chown -R equipment:equipment /home/equipment/.rbenv
```

Вариант B — скопируйте исходник Ruby в кэш rbenv:
```bash
mkdir -p /home/equipment/.rbenv/cache
cp ruby-3.4.1.tar.bz2 /home/equipment/.rbenv/cache/
sudo -u equipment -i
rbenv install 3.4.1  # Установит из кэша
```

---

## 4. Установка приложения

### Автоматическая установка

```bash
# На сервере:
cd /tmp
tar -xzf equipment-offline.tar.gz
cd equipment-offline/equipment   # или куда распаковался
sudo bash deploy/install.sh
```

### Ручная установка

```bash
# 1. Распаковка
sudo mkdir -p /opt/equipment
sudo tar -xzf equipment-offline.tar.gz -C /opt/equipment --strip-components=1
sudo chown -R equipment:equipment /opt/equipment

# 2. Установка gem-ов из кэша
sudo -u equipment -i
cd /opt/equipment
bundle config set --local deployment true
bundle config set --local without 'development test'
bundle config set --local path vendor/bundle
bundle install --local  # Устанавливает из vendor/cache без интернета!

# 3. Создание директорий
mkdir -p log tmp/pids tmp/cache tmp/sockets storage
```

---

## 5. Настройка PostgreSQL

```bash
# Создание роли и баз данных
sudo -u postgres psql

CREATE ROLE equipment WITH LOGIN PASSWORD 'ваш_пароль' CREATEDB;
CREATE DATABASE equipment_production OWNER equipment;
CREATE DATABASE equipment_production_cache OWNER equipment;
CREATE DATABASE equipment_production_queue OWNER equipment;
CREATE DATABASE equipment_production_cable OWNER equipment;
\q
```

```bash
# Миграция
sudo -u equipment -i
cd /opt/equipment
source .env
bin/rails db:migrate
bin/rails db:migrate:cache
bin/rails db:migrate:queue
bin/rails db:migrate:cable

# Начальные данные (типы оборудования)
bin/rails db:seed

# Создание администратора
bin/rails console
> User.create!(email: 'admin@airport.ru', login: 'admin', password: 'SecurePassword123!', role: :admin, first_name: 'Админ', last_name: 'Системы')
> exit
```

---

## 6. Настройка переменных окружения

Отредактируйте файл `/opt/equipment/.env`:

```bash
sudo -u equipment nano /opt/equipment/.env
```

```env
# === ОБЯЗАТЕЛЬНЫЕ ===
RAILS_ENV=production
SECRET_KEY_BASE=<сгенерированный_ключ>        # openssl rand -hex 64
EQUIPMENT_DATABASE_PASSWORD=<пароль_postgres>
DATABASE_HOST=localhost
DATABASE_PORT=5432
PORT=3000
WEB_CONCURRENCY=2                               # Кол-во воркеров Puma
RAILS_MAX_THREADS=5                             # Потоков на воркер
FORCE_SSL=false                                 # true если за SSL-proxy
ASSUME_SSL=false                                # true если за SSL-proxy

# === LDAP (опционально) ===
LDAP_HOST=ldap.airport.ru
LDAP_PORT=389
LDAP_BASE=dc=airport,dc=ru
LDAP_BIND_DN=cn=admin,dc=airport,dc=ru
LDAP_BIND_PASSWORD=ldap_password

# === SMTP (опционально) ===
SMTP_HOST=mail.airport.ru
SMTP_PORT=587
SMTP_DOMAIN=airport.ru
SMTP_USER=equipment@airport.ru
SMTP_PASSWORD=smtp_password
APP_HOST=equipment.airport.ru
```

---

## 7. Запуск и проверка

### Systemd сервисы

```bash
# Копирование сервисов
sudo cp /opt/equipment/deploy/equipment-web.service /etc/systemd/system/
sudo cp /opt/equipment/deploy/equipment-queue.service /etc/systemd/system/

# ВАЖНО: Обновите переменные в сервисах!
sudo nano /etc/systemd/system/equipment-web.service
# Замените REPLACE_ME на реальные значения из .env

sudo systemctl daemon-reload
sudo systemctl enable equipment-web equipment-queue
sudo systemctl start equipment-web
sudo systemctl start equipment-queue
```

### Проверка

```bash
# Статус сервисов
systemctl status equipment-web
systemctl status equipment-queue

# Логи
journalctl -u equipment-web -f
journalctl -u equipment-queue -f

# Health check
curl http://localhost:3000/up
# Ожидаемый ответ: 200 OK
```

---

## 8. Настройка Nginx

```bash
# Копирование конфигурации
sudo cp /opt/equipment/deploy/nginx-equipment.conf /etc/nginx/sites-available/equipment
sudo ln -sf /etc/nginx/sites-available/equipment /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Настройка имени сервера
sudo nano /etc/nginx/sites-available/equipment
# Замените 'equipment.local' на IP или домен сервера

# Проверка и перезагрузка
sudo nginx -t
sudo systemctl reload nginx
```

Теперь приложение доступно по адресу: `http://<IP_сервера>/`

---

## 9. Настройка LDAP

Если в организации есть LDAP/Active Directory:

1. Добавьте переменные в `/opt/equipment/.env`
2. Отредактируйте `/opt/equipment/config/ldap.yml` при необходимости
3. Перезапустите: `sudo systemctl restart equipment-web`

Пользователи смогут входить своим доменным логином. При первом входе
будет автоматически создан аккаунт с ролью `viewer`.

**Встроенный администратор:** `administrator` / `Administrator1!`
(работает всегда, без LDAP)

---

## 10. Настройка почты (SMTP)

Для отправки актов ремонта по email:

1. Добавьте SMTP переменные в `.env`
2. Настройте адрес ремонтной организации в `config/initializers/repair_config.rb`
3. Перезапустите: `sudo systemctl restart equipment-web`

---

## 11. Обновление

### Автоматическое обновление

```bash
# 1. На разработческой машине собрать новый пакет
bash deploy/prepare_offline_package.sh

# 2. Скопировать на сервер
scp equipment-offline-YYYYMMDD.tar.gz user@server:/tmp/

# 3. На сервере
cd /tmp
tar -xzf equipment-offline-YYYYMMDD.tar.gz
sudo bash /opt/equipment/deploy/update.sh /tmp/equipment-offline/equipment
```

### Ручное обновление

```bash
# 1. Остановить сервисы
sudo systemctl stop equipment-queue equipment-web

# 2. Резервная копия
sudo -u equipment bash /opt/equipment/deploy/backup.sh

# 3. Обновить файлы (НЕ затирайте .env!)
sudo rsync -a --exclude='.env' --exclude='storage/' --exclude='log/' \
  /tmp/new-version/ /opt/equipment/

# 4. Установить зависимости
sudo -u equipment -i
cd /opt/equipment
source .env
bundle install --local
bin/rails db:migrate
bin/rails assets:precompile

# 5. Запустить
exit  # из-под equipment
sudo systemctl start equipment-web equipment-queue
```

---

## 12. Резервное копирование

### Ручной запуск

```bash
sudo -u equipment bash /opt/equipment/deploy/backup.sh
```

### Автоматическое (cron)

```bash
sudo crontab -u equipment -e

# Ежедневно в 02:00
0 2 * * * /opt/equipment/deploy/backup.sh >> /opt/equipment/log/backup.log 2>&1
```

### Восстановление из бэкапа

```bash
# Восстановление БД
sudo -u equipment pg_restore -h localhost -U equipment -d equipment_production \
  --clean --if-exists /opt/equipment/backups/db_YYYYMMDD_HHMMSS.dump

# Восстановление файлов
sudo -u equipment tar -xzf /opt/equipment/backups/storage_YYYYMMDD.tar.gz \
  -C /opt/equipment/
```

---

## 13. Мониторинг и диагностика

### Логи приложения

```bash
# Puma (web)
journalctl -u equipment-web -f

# Solid Queue (фоновые задачи)
journalctl -u equipment-queue -f

# Nginx
tail -f /var/log/nginx/equipment_access.log
tail -f /var/log/nginx/equipment_error.log

# Rails production log
tail -f /opt/equipment/log/production.log
```

### Проверка состояния

```bash
# Health check
curl -s http://localhost:3000/up

# Статус PostgreSQL
sudo -u postgres pg_isready

# Подключение к Rails console
sudo -u equipment -i
cd /opt/equipment
RAILS_ENV=production bundle exec rails console

# Проверка статистики БД
> ActiveRecord::Base.connection.execute("SELECT count(*) FROM cute_equipments").first
> ActiveRecord::Base.connection.execute("SELECT count(*) FROM audits").first
```

### Очистка

```bash
# Очистка старых логов
sudo -u equipment -i
cd /opt/equipment
bin/rails log:clear

# Очистка старых аудит-записей (> 1 года)
RAILS_ENV=production bin/rails console
> Audit.where("created_at < ?", 1.year.ago).delete_all
```

---

## 14. Решение проблем

### Приложение не запускается

```bash
# Проверьте логи
journalctl -u equipment-web --no-pager -n 50

# Частые причины:
# 1. Не настроен SECRET_KEY_BASE → openssl rand -hex 64
# 2. Ошибка подключения к БД → проверьте .env и pg_hba.conf
# 3. Ошибка миграции → bin/rails db:migrate
```

### Ошибка 502 Bad Gateway (Nginx)

```bash
# Puma не запущен
systemctl status equipment-web

# Порт занят
ss -tlnp | grep 3000

# Перезапуск
sudo systemctl restart equipment-web
```

### Медленная работа

```bash
# Проверка индексов БД
sudo -u equipment -i
cd /opt/equipment
RAILS_ENV=production bin/rails console
> ActiveRecord::Base.connection.execute("SELECT indexrelname, idx_scan, idx_tup_read FROM pg_stat_user_indexes ORDER BY idx_scan DESC LIMIT 20").to_a

# Проверка использования памяти
free -m
ps aux --sort=-%mem | head -5

# Очистка кэша
bin/rails tmp:clear
```

### LDAP не работает

```bash
# Тест подключения к LDAP
ldapsearch -x -H ldap://ldap.airport.ru -b "dc=airport,dc=ru" -D "cn=admin,dc=airport,dc=ru" -w password "(uid=testuser)"

# Проверка конфигурации
cat /opt/equipment/config/ldap.yml
cat /opt/equipment/.env | grep LDAP
```

---

## Структура файлов на сервере

```
/opt/equipment/
├── app/                    # Код приложения
├── config/                 # Конфигурация
├── db/                     # Миграции
├── deploy/                 # Скрипты развёртывания
│   ├── install.sh          # Установка
│   ├── update.sh           # Обновление
│   ├── backup.sh           # Резервное копирование
│   ├── prepare_offline_package.sh  # Сборка пакета
│   ├── equipment-web.service       # Systemd: Puma
│   ├── equipment-queue.service     # Systemd: Solid Queue
│   └── nginx-equipment.conf       # Nginx конфигурация
├── docs/                   # Документация
├── log/                    # Логи
├── public/                 # Статические файлы + ассеты
├── storage/                # Загруженные файлы
├── tmp/                    # Временные файлы
├── vendor/cache/           # Кэш gem-ов (для оффлайн)
├── vendor/bundle/          # Установленные gem-ы
├── .env                    # Переменные окружения (НЕ КОММИТИТЬ!)
├── Gemfile                 # Зависимости Ruby
└── Gemfile.lock            # Зафиксированные версии
```
