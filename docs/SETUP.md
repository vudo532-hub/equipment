# Настройка LDAP и Email для Equipment

## 1. Настройка LDAP

### 1.1 Конфигурация

Файл: `config/ldap.yml`

Необходимые параметры:
- `host` — адрес LDAP-сервера (например, `dc01.corp.company.com`)
- `port` — порт (389 для LDAP, 636 для LDAPS)
- `base` — базовый DN для поиска (например, `"DC=corp,DC=company,DC=com"`)
- `attribute` — атрибут логина (`sAMAccountName` для Active Directory)
- `ssl` — `true` для LDAPS (порт 636), `false` для LDAP (порт 389)
- `admin_user` — DN сервисного аккаунта для поиска пользователей (опционально)
- `admin_password` — пароль сервисного аккаунта (опционально)

### 1.2 Переменные окружения (production)

```bash
LDAP_HOST=dc01.corp.company.com
LDAP_PORT=389
LDAP_BASE_DN="DC=corp,DC=company,DC=com"
LDAP_SSL=false
LDAP_ADMIN_USER="CN=svc-equipment,OU=Service Accounts,DC=corp,DC=company,DC=com"
LDAP_ADMIN_PASSWORD=секретный_пароль
```

### 1.3 Проверка подключения

Из Rails console:

```ruby
require 'net/ldap'
ldap = Net::LDAP.new(host: 'dc01.corp.company.com', port: 389)
ldap.auth('CN=svc-equipment,...', 'password')
puts ldap.bind ? "OK" : ldap.get_operation_result.message
```

### 1.4 Fallback-администратор

- **Логин:** `administrator`
- **Пароль:** `allvanity`
- Этот аккаунт работает без LDAP и всегда доступен.
- Создаётся при запуске `rails db:seed`.

### 1.5 Как работает авторизация

1. Пользователь вводит **логин** (sAMAccountName) и **пароль**
2. Если логин = `administrator` → проверяется пароль в локальной БД (fallback)
3. Иначе → система пытается аутентифицировать через LDAP:
   - Ищет пользователя в LDAP по `sAMAccountName`
   - Если найден → выполняет bind с паролем пользователя
   - При первом входе создаётся запись в БД с ролью `viewer`
   - При повторном входе — находится существующий пользователь
4. Если LDAP недоступен или не настроен — стратегия пропускается

---

## 2. Настройка Email (SMTP для исходящей почты)

### 2.1 Конфигурация SMTP

Файл: `config/environments/production.rb` — уже настроен, нужно только задать переменные окружения.

### 2.2 Переменные окружения для SMTP

```bash
SMTP_HOST=mail.company.com
SMTP_PORT=587
SMTP_DOMAIN=company.com
SMTP_USER=equipment@company.com
SMTP_PASSWORD=пароль_почты
```

### 2.3 Настройка адресов ремонта

```bash
REPAIR_EMAIL_TO=repair-service@company.com        # Куда отправлять заявки
REPAIR_EMAIL_REPLY_TO=equipment-inbox@company.com  # Откуда ждать ответы
REPAIR_EMAIL_FROM=equipment@company.com            # От кого отправляются письма
```

Файл конфигурации: `config/initializers/repair_config.rb`

---

## 3. Настройка Action Mailbox (входящая почта)

### 3.1 Выбор ingress

Варианты:
- `:relay` — для собственного почтового сервера (Postfix/Exim)
- `:mailgun` — для Mailgun
- `:sendgrid` — для SendGrid
- `:mandrill` — для Mandrill

Настройка в `config/environments/production.rb`:

```ruby
config.action_mailbox.ingress = :relay
```

### 3.2 Для ingress :relay (собственный почтовый сервер)

1. Настроить MX-запись домена на сервер приложения
2. Настроить Postfix для пересылки писем на:
   ```
   https://your-app.com/rails/action_mailbox/relay/inbound_emails
   ```
3. Установить пароль:
   ```bash
   bin/rails credentials:edit
   ```
   Добавить:
   ```yaml
   action_mailbox:
     ingress_password: ваш_секретный_пароль
   ```

### 3.3 Тестирование входящей почты

В development: http://localhost:3000/rails/conductor/action_mailbox/inbound_emails

Отправить тестовое письмо:
- **Тема:** `Re: Заявка на ремонт REP-2026-001`
- **Тело:** `Заявка №12345 принята в работу`

Результат: система найдёт акт REP-2026-001 и проставит номер заявки 12345 на всё оборудование в акте.

### 3.4 Как обрабатываются входящие письма

1. Письмо попадает в `RepairReplyMailbox`
2. Из темы извлекается номер акта (формат `REP-YYYY-NNN`)
3. Из тела извлекается номер заявки (формат: `Заявка №XXXXX`, `Ticket #XXXXX`, `№ XXXXX`)
4. Если номер заявки найден:
   - Обновляется статус акта → `in_progress`
   - Номер заявки проставляется на все элементы акта
   - Номер заявки проставляется на само оборудование
5. Если номер заявки не найден — просто обновляется статус и добавляется заметка

---

## 4. Роли пользователей

| Роль    | Просмотр | Редактирование | Отправка в ремонт | Управление ролями |
|---------|----------|----------------|--------------------|-------------------|
| viewer  | ✅       | ❌             | ❌                 | ❌                |
| editor  | ✅       | ✅             | ✅                 | ❌                |
| manager | ✅       | ✅             | ✅                 | ❌                |
| admin   | ✅       | ✅             | ✅                 | ✅                |

- Первый вход через LDAP → роль `viewer`
- Администратор меняет роли через: **Админ → Пользователи**

---

## 5. Быстрый старт

```bash
# 1. Установка зависимостей
bundle install

# 2. Миграции
bin/rails db:migrate

# 3. Начальные данные
bin/rails db:seed

# 4. Запуск
bin/dev
```

Данные для входа:
- **Локальный администратор:** `administrator` / `allvanity`
- **Администратор:** `nn.sirotkin` / `SecureAdmin1!`
- **Тест-пользователь:** `testuser` / `Secure1Pass`
