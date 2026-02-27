# Промпты по доработке приложения Equipment: LDAP-авторизация и ремонтные заявки

> **Проект:** https://github.com/vudo532-hub/equipment  
> **Стек:** Rails 8.0.4 · Turbo · Stimulus · PostgreSQL · Tailwind CSS · Devise · Pundit  
> **Модель:** Opus 4.6  
> **В Git ничего сохранять не нужно — только разработка**

***

## Промпт 1 — LDAP-авторизация с fallback на локального администратора

```
Переработай систему авторизации в проекте Equipment (Rails 8.0.4, Devise, PostgreSQL).

=== ТЕКУЩЕЕ СОСТОЯНИЕ ===
- Авторизация через Devise :database_authenticatable с регистрацией
- Модель User: email, encrypted_password, first_name, last_name, role (enum: viewer/editor/manager/admin)
- Контроллеры: Users::SessionsController, Users::RegistrationsController (стандартные Devise)
- Роли управляются через Admin::UsersController (только admin может менять роли)
- Валидация strong_password при создании/смене пароля

=== ЧТО НУЖНО СДЕЛАТЬ ===

1. Подключить LDAP-аутентификацию как ОСНОВНОЙ способ входа:
   - Добавить gem 'net-ldap' в Gemfile (НЕ devise_ldap_authenticatable — он устарел)
   - Создать кастомную Warden-стратегию LdapAuthenticatable
   - Пользователь вводит логин (sAMAccountName) и пароль
   - Система пытается bind к LDAP-серверу с этими credentials
   - Если LDAP-bind успешен:
     * Ищем пользователя в БД по email (из LDAP-атрибута mail)
     * Если не найден — создаём нового User (first_name и last_name из LDAP-атрибутов givenName и sn)
     * При ПЕРВОМ входе роль = viewer (только просмотр)
     * Авторизуем пользователя
   - Если LDAP-bind неудачен — переходим к fallback

2. Fallback для локального администратора:
   - Если логин = "administrator" и пароль = "allvanity" → входим как admin
   - Этот пользователь создаётся в seeds.rb с ролью admin
   - Обычная Devise :database_authenticatable аутентификация для этого пользователя
   - НЕ проверяем LDAP для логина "administrator"

3. Убрать регистрацию (Sign Up):
   - Удалить devise :registerable из модели User
   - Удалить маршруты регистрации
   - Удалить контроллер Users::RegistrationsController
   - Новые пользователи появляются ТОЛЬКО через LDAP (первый вход) или seeds

4. Обновить форму входа:
   - Поле "Логин" (вместо Email) — принимает sAMAccountName или "administrator"
   - Поле "Пароль"
   - Кнопка "Войти"
   - Убрать ссылки "Зарегистрироваться" и "Забыли пароль?"
   - Дизайн: минималистичный, Tailwind CSS, без анимаций

5. Добавить поле login в модель User:
   - Миграция: add_column :users, :login, :string
   - Индекс: add_index :users, :login, unique: true
   - Для LDAP-пользователей login = sAMAccountName
   - Для администратора login = "administrator"

=== КОНФИГУРАЦИЯ LDAP ===
Настройки LDAP должны храниться в config/ldap.yml:

development:
  host: ldap.example.com
  port: 389
  base: "DC=corp,DC=example,DC=com"
  attribute: sAMAccountName
  ssl: false

production:
  host: <%= ENV['LDAP_HOST'] %>
  port: <%= ENV['LDAP_PORT'] || 389 %>
  base: <%= ENV['LDAP_BASE_DN'] %>
  attribute: sAMAccountName
  ssl: <%= ENV['LDAP_SSL'] || false %>

=== ФАЙЛЫ ДЛЯ СОЗДАНИЯ/ИЗМЕНЕНИЯ ===
- Gemfile: добавить gem 'net-ldap'
- config/ldap.yml: новый файл конфигурации LDAP
- lib/ldap_authenticator.rb: класс для LDAP-операций (bind, поиск атрибутов)
- app/strategies/ldap_strategy.rb: кастомная Warden-стратегия
- config/initializers/devise.rb: подключить кастомную стратегию через config.warden
- config/initializers/ldap.rb: загрузка LDAP-конфига
- app/models/user.rb: убрать :registerable, добавить login, метод find_or_create_from_ldap
- app/controllers/users/sessions_controller.rb: переопределить create для поддержки login
- app/views/devise/sessions/new.html.erb: новая форма входа (login + password)
- db/migrate/xxx_add_login_to_users.rb: миграция
- db/seeds.rb: обновить — создать administrator с login="administrator", password="allvanity"
- config/routes.rb: убрать registrations

=== СТРУКТУРА СТРАТЕГИИ (Warden) ===
# app/strategies/ldap_strategy.rb
require 'net/ldap'

class LdapStrategy < Devise::Strategies::Authenticatable
  def valid?
    login.present? && password.present? && login != 'administrator'
  end

  def authenticate!
    ldap_config = YAML.safe_load(
      ERB.new(File.read(Rails.root.join('config', 'ldap.yml'))).result,
      permitted_classes: [], permitted_symbols: [], aliases: true
    )[Rails.env]

    ldap = Net::LDAP.new(
      host: ldap_config['host'],
      port: ldap_config['port'],
      encryption: ldap_config['ssl'] ? :simple_tls : nil
    )

    # Поиск DN пользователя
    ldap.auth(ldap_config['admin_user'], ldap_config['admin_password']) if ldap_config['admin_user']
    
    filter = Net::LDAP::Filter.eq(ldap_config['attribute'], login)
    result = ldap.search(base: ldap_config['base'], filter: filter, return_result: true)&.first

    if result.nil?
      fail!('Пользователь не найден в LDAP')
      return
    end

    # Попытка bind с паролем пользователя
    ldap.auth(result.dn, password)
    if ldap.bind
      user = User.find_or_create_from_ldap(login, result)
      success!(user)
    else
      fail!('Неверный пароль LDAP')
    end
  end

  private

  def login
    params.dig('user', 'login')&.strip&.downcase
  end

  def password
    params.dig('user', 'password')
  end
end

Warden::Strategies.add(:ldap_authenticatable, LdapStrategy)

=== МЕТОД В МОДЕЛИ USER ===
# app/models/user.rb
def self.find_or_create_from_ldap(login, ldap_entry)
  email = ldap_entry[:mail]&.first&.downcase
  return nil if email.blank?

  user = find_by(login: login) || find_by(email: email)
  
  if user.nil?
    user = new(
      login: login,
      email: email,
      first_name: ldap_entry[:givenname]&.first || login,
      last_name: ldap_entry[:sn]&.first || '',
      password: SecureRandom.hex(32),
      role: :viewer
    )
    user.save!
  else
    user.update!(login: login) if user.login.blank?
  end
  
  user
end

=== ТРЕБОВАНИЯ К ОПТИМИЗАЦИИ ===
- Никаких CSS-анимаций, transitions, transform
- LDAP-bind должен быть с таймаутом (connect_timeout: 5, read_timeout: 5)
- Логировать LDAP-ошибки в Rails.logger.error
- Не кешировать LDAP-соединения (создавать новое на каждый запрос)
- Тесты LDAP не нужны (нет тестового LDAP-сервера)
```

***

## Промпт 2 — Ремонтные заявки через email

```
Реализуй систему отправки оборудования в ремонт через email в проекте Equipment.

=== ТЕКУЩЕЕ СОСТОЯНИЕ ===
- Существуют модели: RepairBatch (repair_number, status, notes), RepairBatchItem (equipment_type, equipment_id, system, serial_number, model, inventory_number, repair_ticket_number)
- Маршруты: resources :repairs с create_batch, history, update_ticket_number, export_to_excel
- Статусы оборудования включают: waiting_repair, ready_to_dispatch (в CuteEquipment)
- Модели: CuteEquipment, FidsEquipment, ZamarEquipment — все имеют поле repair_ticket_number
- Action Mailer настроен в production (SMTP закомментирован — нужно раскомментировать)

=== ЧТО НУЖНО СДЕЛАТЬ ===

### Часть A: Отправка заявки на ремонт

1. Добавить кнопку "Отправить в ремонт" в карточку оборудования (для каждой подсистемы):
   - Кнопка видна только для ролей editor, manager, admin
   - При нажатии: модальное окно (Turbo Frame) с формой:
     * Тема письма (автозаполнение: "Заявка на ремонт [система] — [инв.номер]")
     * Текст заявки (textarea, шаблон по умолчанию с данными оборудования)
     * Кнопка "Отправить заявку"

2. При отправке:
   - Создать RepairBatch с одним RepairBatchItem
   - Сформировать и отправить email через Action Mailer:
     * От: настраиваемый адрес (config)
     * Кому: настраиваемый адрес ремонтной службы (config)
     * Reply-To: адрес для приёма входящих писем (config)
     * Тема: "Заявка на ремонт [REP-2026-XXX] — [инв.номер] [серийный номер]"
     * Тело: данные оборудования (тип, модель, инв.номер, серийный номер, терминал, место установки, примечание)
   - Изменить статус оборудования на waiting_repair
   - Отвязать оборудование от места установки (set installation_id = nil)
   - Записать в аудит лог

3. Mailer (app/mailers/repair_mailer.rb):
   class RepairMailer < ApplicationMailer
     def repair_request(repair_batch)
       @batch = repair_batch
       @items = repair_batch.repair_batch_items.includes(:repair_batch)
       
       mail(
         to: Rails.application.config.repair_email_to,
         reply_to: Rails.application.config.repair_email_reply_to,
         subject: "Заявка на ремонт #{@batch.repair_number}"
       )
     end
   end

### Часть B: Приём ответа с номером заявки (Action Mailbox)

1. Подключить Action Mailbox:
   - rails action_mailbox:install
   - Настроить ingress (relay или mailgun/sendgrid — зависит от инфраструктуры)
   - Создать mailbox для обработки ответов:

   # app/mailboxes/repair_reply_mailbox.rb
   class RepairReplyMailbox < ApplicationMailbox
     # Роутинг: письма на repair@... или содержащие REP-XXXX-XXX в теме
     REPAIR_NUMBER_PATTERN = /REP-\d{4}-\d{3}/i

     def process
       repair_number = extract_repair_number
       return bounce_with_notification unless repair_number

       batch = RepairBatch.find_by(repair_number: repair_number)
       return bounce_with_notification unless batch

       ticket_number = extract_ticket_number
       
       if ticket_number.present?
         update_batch_with_ticket(batch, ticket_number)
       else
         # Просто обновляем статус что ответ получен
         batch.update!(status: 'in_progress', notes: append_note(batch.notes, "Получен ответ: #{mail.subject}"))
       end
     end

     private

     def extract_repair_number
       # Ищем в теме письма
       subject = mail.subject.to_s
       match = subject.match(REPAIR_NUMBER_PATTERN)
       match ? match.upcase : nil
     end

     def extract_ticket_number
       # Ищем номер заявки в теле письма (формат настраивается)
       # Примеры: "Заявка №12345", "Ticket #12345", "№ 12345"
       body_text = mail.text_part&.body&.decoded || mail.body&.decoded || ''
       
       patterns = [
         /(?:заявка|ticket|номер заявки|№)\s*[#№]?\s*(\d{4,10})/i,
         /(?:request|req)\s*[#:]?\s*(\d{4,10})/i
       ]
       
       patterns.each do |pattern|
         match = body_text.match(pattern)
         return match[^1] if match
       end
       
       nil
     end

     def update_batch_with_ticket(batch, ticket_number)
       ActiveRecord::Base.transaction do
         batch.update!(
           status: 'in_progress',
           notes: append_note(batch.notes, "Номер заявки: #{ticket_number}")
         )
         
         batch.repair_batch_items.each do |item|
           item.update!(repair_ticket_number: ticket_number)
           
           # Обновляем repair_ticket_number на самом оборудовании
           equipment = item.equipment
           equipment&.update!(repair_ticket_number: ticket_number) if equipment
         end
       end
     end

     def append_note(existing, new_note)
       timestamp = Time.current.strftime('%d.%m.%Y %H:%M')
       [existing, "[#{timestamp}] #{new_note}"].compact.join("\n")
     end

     def bounce_with_notification
       Rails.logger.warn("RepairReplyMailbox: не удалось обработать письмо — #{mail.subject}")
     end
   end

2. Роутинг mailbox (app/mailboxes/application_mailbox.rb):
   class ApplicationMailbox < ActionMailbox::Base
     routing /repair|ремонт/i => :repair_reply
     routing RepairReplyMailbox::REPAIR_NUMBER_PATTERN => :repair_reply
   end

### Часть C: Отображение статуса ремонта

1. В карточке оборудования показывать:
   - Статус "Ожидает ремонта" (жёлтый бейдж) / "В ремонте" (оранжевый бейдж)
   - Номер заявки (repair_ticket_number) если есть
   - Номер партии ремонта (repair_number из RepairBatch)
   - Кнопка "Вернуть из ремонта" (для manager/admin):
     * Меняет статус оборудования на active
     * Обновляет статус RepairBatch на received

=== КОНФИГУРАЦИЯ EMAIL ===
Все настройки email должны быть в config/application.rb или через ENV:

# config/initializers/repair_config.rb
Rails.application.config.repair_email_to = ENV.fetch('REPAIR_EMAIL_TO', 'repair@example.com')
Rails.application.config.repair_email_reply_to = ENV.fetch('REPAIR_EMAIL_REPLY_TO', 'equipment-repair@example.com')
Rails.application.config.repair_email_from = ENV.fetch('REPAIR_EMAIL_FROM', 'equipment@example.com')

=== ФАЙЛЫ ДЛЯ СОЗДАНИЯ/ИЗМЕНЕНИЯ ===
- app/mailers/repair_mailer.rb: новый mailer
- app/views/repair_mailer/repair_request.html.erb: шаблон письма
- app/views/repair_mailer/repair_request.text.erb: текстовая версия
- app/mailboxes/application_mailbox.rb: роутинг входящей почты
- app/mailboxes/repair_reply_mailbox.rb: обработка ответов
- config/initializers/repair_config.rb: настройки email ремонта
- app/controllers/repairs_controller.rb: обновить create_batch (отправка email)
- app/views/cute_equipments/show: кнопка "Отправить в ремонт", статус ремонта
- app/views/fids_equipments/show: аналогично
- app/views/zamar_equipments/show: аналогично
- app/views/repairs/_repair_modal.html.erb: модальное окно отправки (Turbo Frame)

=== ТРЕБОВАНИЯ К ОПТИМИЗАЦИИ ===
- Отправку email — через Active Job (deliver_later), не блокировать HTTP-запрос
- Action Mailbox — обработка входящих писем асинхронно (Active Job)
- Никаких CSS-анимаций
- Транзакции при обновлении статуса оборудования + RepairBatch
- Eager loading для repair_batch_items в отображении
```

***

## Промпт 3 — Мини-инструкция по настройке LDAP и почты

```
Создай файл docs/SETUP.md с инструкцией по настройке LDAP и почтовой системы для проекта Equipment.

=== СОДЕРЖАНИЕ ИНСТРУКЦИИ ===

# Настройка LDAP и Email для Equipment

## 1. Настройка LDAP

### 1.1 Конфигурация
Файл: config/ldap.yml

Необходимые параметры:
- host: адрес LDAP-сервера (например, dc01.corp.company.com)
- port: порт (389 для LDAP, 636 для LDAPS)
- base: базовый DN для поиска (например, "DC=corp,DC=company,DC=com")
- attribute: атрибут логина (sAMAccountName для Active Directory)
- ssl: true для LDAPS (порт 636), false для LDAP (порт 389)
- admin_user: DN сервисного аккаунта для поиска пользователей (опционально)
- admin_password: пароль сервисного аккаунта (опционально)

### 1.2 Переменные окружения (production)
LDAP_HOST=dc01.corp.company.com
LDAP_PORT=389
LDAP_BASE_DN="DC=corp,DC=company,DC=com"
LDAP_SSL=false
LDAP_ADMIN_USER="CN=svc-equipment,OU=Service Accounts,DC=corp,DC=company,DC=com"
LDAP_ADMIN_PASSWORD=секретный_пароль

### 1.3 Проверка подключения
Команда из Rails console:
  require 'net/ldap'
  ldap = Net::LDAP.new(host: 'dc01.corp.company.com', port: 389)
  ldap.auth('CN=svc-equipment,...', 'password')
  puts ldap.bind ? "OK" : ldap.get_operation_result.message

### 1.4 Fallback-администратор
Логин: administrator
Пароль: allvanity
Этот аккаунт работает без LDAP и всегда доступен.

## 2. Настройка Email (SMTP для исходящей почты)

### 2.1 Конфигурация SMTP
Файл: config/environments/production.rb

config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: ENV['SMTP_HOST'],
  port: ENV.fetch('SMTP_PORT', 587),
  domain: ENV['SMTP_DOMAIN'],
  user_name: ENV['SMTP_USER'],
  password: ENV['SMTP_PASSWORD'],
  authentication: :plain,
  enable_starttls_auto: true
}

### 2.2 Переменные окружения для SMTP
SMTP_HOST=mail.company.com
SMTP_PORT=587
SMTP_DOMAIN=company.com
SMTP_USER=equipment@company.com
SMTP_PASSWORD=пароль_почты

### 2.3 Настройка адресов ремонта
REPAIR_EMAIL_TO=repair-service@company.com     # Куда отправлять заявки
REPAIR_EMAIL_REPLY_TO=equipment-inbox@company.com  # Откуда ждать ответы
REPAIR_EMAIL_FROM=equipment@company.com         # От кого отправляются письма

## 3. Настройка Action Mailbox (входящая почта)

### 3.1 Выбор ingress
Варианты:
- :relay — для собственного почтового сервера (Postfix/Exim)
- :mailgun — для Mailgun
- :sendgrid — для SendGrid
- :mandrill — для Mandrill

Настройка в config/environments/production.rb:
  config.action_mailbox.ingress = :relay

### 3.2 Для ingress :relay (собственный почтовый сервер)
1. Настроить MX-запись домена на сервер приложения
2. Настроить Postfix для пересылки писем на:
   https://your-app.com/rails/action_mailbox/relay/inbound_emails
3. Установить пароль:
   bin/rails credentials:edit
   Добавить:
   action_mailbox:
     ingress_password: ваш_секретный_пароль

### 3.3 Тестирование входящей почты
В development: http://localhost:3000/rails/conductor/action_mailbox/inbound_emails
Отправить тестовое письмо с темой "Re: Заявка на ремонт REP-2026-001" и текстом "Заявка №12345 принята в работу"

## 4. Роли пользователей

| Роль    | Просмотр | Редактирование | Отправка в ремонт | Управление ролями |
|---------|----------|----------------|--------------------|-------------------|
| viewer  | ✅       | ❌             | ❌                 | ❌                |
| editor  | ✅       | ✅             | ✅                 | ❌                |
| manager | ✅       | ✅             | ✅                 | ❌                |
| admin   | ✅       | ✅             | ✅                 | ✅                |

Первый вход через LDAP → роль viewer.
Администратор меняет роли через: Админ → Пользователи.

=== ФОРМАТ ===
- Файл docs/SETUP.md в формате Markdown
- Минимум текста, максимум конкретных примеров
- Все секреты — через переменные окружения, никогда не в коде
```

***

## Промпт 4 — Финальная проверка и интеграция

```
Проверь и исправь интеграцию LDAP-авторизации и ремонтных заявок через email в проекте Equipment.

=== КОНТРОЛЬНЫЙ СПИСОК ===

### Авторизация
1. [ ] Вход через LDAP работает: ввожу sAMAccountName + пароль → вхожу
2. [ ] Первый LDAP-вход создаёт пользователя с ролью viewer
3. [ ] Повторный LDAP-вход находит существующего пользователя
4. [ ] Fallback: логин "administrator" / пароль "allvanity" → вхожу как admin
5. [ ] Страница регистрации недоступна (404 или redirect)
6. [ ] Ссылка "Забыли пароль?" убрана
7. [ ] В навигации отображается имя пользователя из LDAP
8. [ ] Admin может менять роли через /admin/users
9. [ ] Viewer не может редактировать оборудование
10. [ ] При ошибке LDAP — понятное сообщение "Ошибка авторизации"

### Ремонт через email
11. [ ] Кнопка "Отправить в ремонт" видна editor/manager/admin
12. [ ] Кнопка НЕ видна viewer
13. [ ] При нажатии открывается модальное окно (Turbo Frame, без анимации)
14. [ ] Отправка создаёт RepairBatch + RepairBatchItem
15. [ ] Email отправляется через deliver_later (не блокирует UI)
16. [ ] Статус оборудования = waiting_repair
17. [ ] Оборудование отвязано от места установки
18. [ ] В аудит-логе запись об отправке в ремонт
19. [ ] Входящее письмо с номером заявки → repair_ticket_number обновлён
20. [ ] Номер заявки отображается в карточке оборудования
21. [ ] Кнопка "Вернуть из ремонта" работает (manager/admin)

### Производительность
22. [ ] Нет CSS-анимаций (transitions, keyframes, transform)
23. [ ] LDAP-bind с таймаутом 5 секунд
24. [ ] Email через Active Job (deliver_later)
25. [ ] Action Mailbox — асинхронная обработка
26. [ ] Eager loading: includes(:repair_batch_items) где нужно
27. [ ] Индексы на: users.login, repair_batches.repair_number

### Безопасность
28. [ ] LDAP-пароли не логируются
29. [ ] Секреты через ENV или Rails credentials
30. [ ] Pundit policy: только editor+ может создавать заявки на ремонт
31. [ ] CSRF-защита для Action Mailbox (ingress password)

=== ДЕЙСТВИЯ ===
- Пройди по каждому пункту
- Проверь что все файлы созданы и корректны
- Исправь найденные проблемы
- Убедись что миграции выполняются без ошибок: rails db:migrate
- Убедись что seeds работают: rails db:seed
- Проверь что маршруты корректны: rails routes | grep -E "repair|session|user"

=== ЕСЛИ ЧТО-ТО СЛОМАЛОСЬ ===
- Покажи diff изменений
- Объясни что было не так и как исправлено
- Не добавляй новый функционал — только исправления
```

***

## Порядок выполнения

| Шаг | Промпт | Что делается | Зависимости |
|-----|--------|-------------|-------------|
| 1 | Промпт 1 | LDAP-авторизация + fallback administrator | — |
| 2 | Промпт 2 | Ремонтные заявки через email + Action Mailbox | Зависит от ролей (Промпт 1) |
| 3 | Промпт 3 | Документация по настройке | После Промптов 1 и 2 |
| 4 | Промпт 4 | Финальная проверка и исправления | После всех промптов |

***

## Важные замечания

- **Модель Opus 4.6** — все промпты оптимизированы для этой модели
- **Не сохранять в Git** — только локальная разработка, коммиты делает пользователь вручную
- **Оптимизация** — никаких CSS-анимаций, минимум JS, быстрый отклик
- **Текущая БД** — уже есть repair_batches и repair_batch_items (не нужно создавать заново)
- **Devise уже установлен** — gem 'devise' и gem 'pundit' в Gemfile, контроллеры настроены
- **net-ldap** — используется напрямую вместо устаревшего devise_ldap_authenticatable[^1][^2]
- **Action Mailbox** — встроен в Rails 8, не требует дополнительных gem[^3][^4]

---

## References

1. [custom strategy returning "uninitialized constant Devise::Models::CustomStrategy" · Issue #4106 · heartcombo/devise](https://github.com/heartcombo/devise/issues/4106) - Following the guide to adding a an ldap strategy, I am creating a new custom strategy on version 3.5...

2. [devise_ldap_authenticatable/README.md at default · cschiewek/devise_ldap_authenticatable](https://github.com/cschiewek/devise_ldap_authenticatable/blob/default/README.md) - Devise Module for LDAP . Contribute to cschiewek/devise_ldap_authenticatable development by creating...

3. [Integrate and Troubleshoot Inbound Emails with Action Mailbox in Rails](https://dev.to/appsignal/integrate-and-troubleshoot-inbound-emails-with-action-mailbox-in-rails-6eg) - If you’ve ever looked at the Request for Comments (RFCs) around sending and receiving emails, you’ll...

4. [Processing Incoming Email](https://guides.rubyonrails.org/action_mailbox_basics.html) - This guide provides you with all you need to get started in receiving emails to your application.Aft...

