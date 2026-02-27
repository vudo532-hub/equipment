# План разработки приложения учёта оборудования
## Equipment Management System (EMS)

**Дата создания:** 21 января 2026  
**Язык разработки:** Ruby  
**Фреймворк:** Ruby on Rails 7.1+  
**БД:** SQLite (с миграцией на PostgreSQL при необходимости)  
**Статус:** Готово к разработке

---

## 📋 Содержание плана

1. [Технологический стек](#технологический-стек)
2. [Архитектура приложения](#архитектура-приложения)
3. [Структура базы данных](#структура-базы-данных)
4. [Этапы разработки](#этапы-разработки)
5. [Промпты для Claude Opus 4.5](#промпты-для-claude-opus-45)
6. [Git workflow](#git-workflow)
7. [Развёртывание на изолированной ВМ](#развёртывание-на-изолированной-вм)
8. [Чек-лист проверки версий](#чек-лист-проверки-версий)

---

## 🛠 Технологический стек

### Core Stack
- **Ruby:** 3.3.0 или новее
- **Rails:** 7.1.x
- **БД:** SQLite3 (разработка), возможен переход на PostgreSQL
- **Веб-сервер:** Puma
- **CSS:** Tailwind CSS 3.4+

### Essential Gems (Gemfile)

```ruby
# Core Rails
ruby '3.3.0'
gem 'rails', '~> 7.1.0'
gem 'sqlite3', '~> 1.7'
gem 'puma', '~> 6.4'

# Authentication
gem 'devise', '~> 4.9'
gem 'devise-i18n', '~> 1.12'

# Authorization
gem 'pundit', '~> 2.3'

# Search & Filtering
gem 'ransack', '~> 4.1'

# Pagination
gem 'pagy', '~> 7.2'

# Export (CSV, Excel)
gem 'csv', '~> 3.2'
gem 'write_xlsx', '~> 1.10'

# Audit Log
gem 'audited', '~> 5.3'

# API Support
gem 'api-pagination', '~> 4.8'
gem 'active_model_serializers', '~> 0.10'

# Form handling
gem 'simple_form', '~> 5.3'

# Frontend
gem 'importmap-rails', '~> 2.0'
gem 'stimulus-rails', '~> 1.3'
gem 'tailwindcss-rails', '~> 2.1'
gem 'heroicons', '~> 2.1'

# Validation
gem 'validates_email_format_of', '~> 1.7'

# Utilities
gem 'kaminari', '~> 1.2'
gem 'nilify_blanks', '~> 1.4'
gem 'strip_attributes', '~> 1.13'

# Development/Test
group :development, :test do
  gem 'debug', '~> 1.9'
  gem 'rspec-rails', '~> 6.1'
  gem 'factory_bot_rails', '~> 6.4'
  gem 'faker', '~> 3.2'
  gem 'rubocop', '~> 1.60', require: false
  gem 'rubocop-rails', '~> 2.22', require: false
end

group :development do
  gem 'web-console', '~> 4.2'
end

group :test do
  gem 'shoulda-matchers', '~> 5.3'
  gem 'simplecov', '~> 0.22'
end
```

### Версии по состоянию на 2026 год
| Компонент | Версия | Статус |
|-----------|--------|--------|
| Ruby | 3.3.0+ | Stable |
| Rails | 7.1.x | LTS |
| Devise | 4.9.x | Stable |
| Ransack | 4.1.x | Stable |
| Tailwind | 3.4.x | Stable |
| Audited | 5.3.x | Stable |

---

## 🏗 Архитектура приложения

### Models (Модели)

```
User
├── has_many :cute_installations (места установки CUTE)
├── has_many :fids_installations (места установки FIDS)
├── has_many :cute_equipments (оборудование CUTE)
├── has_many :fids_equipments (оборудование FIDS)
└── has_many :audit_logs (через audited)

CuteInstallation (Место установки CUTE)
├── belongs_to :user
├── has_many :cute_equipments
├── has_many :audit_logs (as: :auditable)
└── validates: name, installation_type, identifier

FidsInstallation (Место установки FIDS)
├── belongs_to :user
├── has_many :fids_equipments
├── has_many :audit_logs
└── validates: name, installation_type, identifier

CuteEquipment (Оборудование CUTE)
├── belongs_to :user
├── belongs_to :cute_installation
├── has_many :audit_logs
└── fields: type, model, inventory_number, serial_number, status, note, last_action_date

FidsEquipment (Оборудование FIDS)
├── belongs_to :user
├── belongs_to :fids_installation
├── has_many :audit_logs
└── fields: type, model, inventory_number, serial_number, status, note, last_action_date

AuditLog
├── belongs_to :user
├── belongs_to :auditable (polymorphic)
└── fields: action, changes, created_at
```

### Controllers

```
/app/controllers
├── pages_controller.rb (главная, меню)
├── cute_installations_controller.rb
├── cute_equipments_controller.rb
├── fids_installations_controller.rb
├── fids_equipments_controller.rb
├── exports_controller.rb (CSV, Excel)
├── audit_logs_controller.rb
└── api/
    ├── v1/cute_equipments_controller.rb
    ├── v1/fids_equipments_controller.rb
    └── v1/audit_logs_controller.rb
```

### Views Structure

```
/app/views
├── pages/
│   ├── dashboard.html.erb (главное меню)
│   └── shared/ (общие компоненты)
│       ├── _header.html.erb
│       ├── _sidebar.html.erb
│       └── _footer.html.erb
├── cute_equipments/
│   ├── index.html.erb (таблица)
│   ├── show.html.erb (карточка)
│   ├── new.html.erb (добавление)
│   └── edit.html.erb (редактирование)
├── cute_installations/
│   ├── index.html.erb
│   ├── show.html.erb
│   └── form/_form.html.erb
├── fids_equipments/
│   └── (аналогично CUTE)
├── fids_installations/
│   └── (аналогично CUTE)
└── audit_logs/
    └── index.html.erb
```

---

## 🗄 Структура базы данных

### Основные таблицы

#### users
```sql
id, email, encrypted_password, created_at, updated_at
```

#### cute_installations
```sql
id, user_id, name, installation_type, identifier, created_at, updated_at
```

#### fids_installations
```sql
id, user_id, name, installation_type, identifier, created_at, updated_at
```

#### cute_equipments
```sql
id, user_id, cute_installation_id, type, model, inventory_number, 
serial_number, status, note, last_action_date, created_at, updated_at
```

#### fids_equipments
```sql
id, user_id, fids_installation_id, type, model, inventory_number, 
serial_number, status, note, last_action_date, created_at, updated_at
```

#### audits (автоматически создаётся gem 'audited')
```sql
id, auditable_type, auditable_id, user_id, action, audited_changes, 
created_at, request_uuid, ip_address
```

---

## 📅 Этапы разработки

### Этап 1: Инициализация проекта (1-2 часа)
- Создание Rails приложения
- Установка и конфигурация Devise
- Настройка Tailwind CSS
- Настройка git репозитория

### Этап 2: Аутентификация (2-3 часа)
- Модель User с Devise
- Формы регистрации и входа
- Защита маршрутов
- Базовая навигация

### Этап 3: Места установки (3-4 часа)
- Models: CuteInstallation, FidsInstallation
- CRUD операции
- Валидации
- Интеграция Audited

### Этап 4: Оборудование CUTE (4-5 часов)
- Model: CuteEquipment
- CRUD операции
- Связь с местами установки
- Синхронизация last_action_date

### Этап 5: Оборудование FIDS (2-3 часа)
- Дублирование логики CUTE для FIDS
- Все компоненты повторяются

### Этап 6: Поиск и фильтрация (3-4 часа)
- Установка Ransack
- Формы фильтрации
- Сортировка по столбцам
- Пагинация Pagy

### Этап 7: Экспорт данных (2-3 часа)
- CSV экспорт с фильтрацией
- Excel экспорт (write_xlsx)
- Фильтрация перед экспортом

### Этап 8: Просмотр истории (2-3 часа)
- Настройка Audited
- Страница audit_logs
- Отображение истории изменений

### Этап 9: API (4-5 часов)
- API endpoints для мобильных приложений
- Serializers
- Authentication tokens (JWT опционально)
- API документация

### Этап 10: Тестирование и оптимизация (3-4 часа)
- RSpec тесты
- Performance tuning
- Проверка совместимости версий

### Этап 11: Подготовка к деплою (2-3 часа)
- Документация
- Миграция на PostgreSQL (при необходимости)
- Настройка для изолированной ВМ

---

## 🤖 Промпты для Claude Opus 4.5

### ПРОМПТ #1: Инициализация проекта и Devise

```
Я создаю Rails 7.1 приложение для учёта оборудования. Мне нужно:

1. Полная пошаговая инструкция по инициализации нового Rails 7.1 проекта с SQLite
2. Установка и конфигурация Devise для аутентификации пользователей
3. Установка и настройка Tailwind CSS 3.4+ для Rails
4. Инициализация git репозитория

Детали:
- Ruby версия 3.3.0
- Rails 7.1.x
- Devise 4.9
- Tailwind CSS 3.4
- Локализация на русский язык (devise-i18n)

Пожалуйста, предоставьте:
- Команды для установки
- Необходимые файлы конфигурации
- Gemfile с правильными версиями
- Структуру папок проекта
- .gitignore файл
- Первоначальные миграции

Убедитесь в совместимости всех версий по состоянию на январь 2026 года.
```

### ПРОМПТ #2: Models и Database Schema

```
Создай Rails модели для системы учёта оборудования:

Требуемые модели:
1. User (с Devise)
2. CuteInstallation (места установки CUTE)
3. FidsInstallation (места установки FIDS)
4. CuteEquipment (оборудование CUTE)
5. FidsEquipment (оборудование FIDS)

Для каждой модели оборудования (CUTE и FIDS) нужны поля:
- ID (первичный ключ)
- Тип оборудования
- Модель
- Инвентарный номер (уникальный в рамках типа)
- Серийный номер
- Статус (enum: active, inactive, maintenance, archived)
- Место установки (foreign key)
- Примечание (текст)
- Дата последнего действия (автоматически обновляется)

Для мест установки:
- Название терминала
- Тип места установки
- Идентификатор места

Требования:
- Все необходимые валидации
- Enum для статусов
- Правильные associations (belongs_to, has_many)
- before_save callback для обновления last_action_date
- Миграции базы данных
- Индексы для производительности (важно для нескольких тысяч записей)
- Скопы для часто используемых фильтров

Используй:
- Rails 7.1
- SQLite для разработки
- Гибкость для миграции на PostgreSQL
- Лучшие практики Rails

Предоставь:
- Модели (.rb файлы)
- Миграции
- Seeds для тестовых данных
```

### ПРОМПТ #3: Аудит логирование и история изменений

```
Настрой аудит логирование для Rails 7.1 приложения учёта оборудования.

Требования:
1. Использовать gem 'audited' для отслеживания всех изменений
2. Для каждой модели оборудования и мест установки вести полную историю
3. Отслеживать: кто сделал изменение, когда, какие поля изменились
4. Хранить IP адрес пользователя при изменении
5. Создать страницу просмотра audit logs с фильтрацией по:
   - Дате
   - Пользователю
   - Типу объекта (CuteEquipment, FidsInstallation и т.д.)
   - Действию (create, update, destroy)

Предоставь:
- Конфигурация audited в моделях
- Миграция для таблицы audits
- AuditLog модель и контроллер
- Представления для отображения истории
- Калькуляция last_action_date для оборудования на основе audit logs
- Seeds с тестовыми данными

Используй:
- gem 'audited' ~> 5.3
- Полиморфные associations
- Timestamps для точного отслеживания времени
```

### ПРОМПТ #4: CRUD для мест установки (Installation Management)

```
Создай полный CRUD функционал для управления местами установки в Rails 7.1.

Нужны контроллеры и представления для:
1. CuteInstallationsController (CUTE места установки)
2. FidsInstallationsController (FIDS места установки)

Функциональность:
- Index: таблица со всеми местами установки с сортировкой, пагинацией
- Show: детальная карточка места установки с количеством оборудования
- New/Create: форма добавления нового места
- Edit/Update: редактирование существующего места
- Delete: удаление места (с проверкой зависимостей)

Требования:
- Использовать simple_form для форм
- Tailwind CSS для стилизации
- Responsive таблицы
- Flash messages для успеха/ошибок
- Валидация на фронте и бэке
- Полная интеграция с Audited
- before_action для авторизации (только текущий пользователь видит свои места)

Предоставь:
- Контроллеры
- Представления (index, show, form, new, edit)
- Маршруты
- Частичные представления (_form, _table)
- Assets (CSS/JS если требуется)

Структура должна быть полностью переиспользуемой для CUTE и FIDS с минимальными отличиями.
```

### ПРОМПТ #5: CRUD для оборудования с синхронизацией

```
Создай полный CRUD функционал для управления оборудованием с особыми требованиями:

Контроллеры:
1. CuteEquipmentsController
2. FidsEquipmentsController

Функциональность:
1. INDEX:
   - Таблица со всем оборудованием
   - Столбцы: ID, Тип, Модель, Инвентарный №, Серийный №, Статус, Место установки, Последнее действие
   - Строки кликабельны → переход на карточку оборудования
   - Постраничная пагинация (20 элементов на странице)

2. SHOW (Карточка оборудования):
   - Все данные оборудования
   - История последних 10 изменений из audit logs
   - Кнопки редактирования и удаления
   - Хлебные крошки навигации

3. NEW/CREATE:
   - Форма с полями: Тип, Модель, Инвентарный №, Серийный №, Статус, Место установки, Примечание
   - Выпадающий список мест установки (только активные)
   - Валидация: инвентарный и серийный номеры должны быть уникальными
   - При создании автоматически устанавливается current_date в last_action_date

4. EDIT/UPDATE:
   - Все поля редактируемы
   - При любом изменении обновляется last_action_date = Time.now
   - Все изменения логируются в Audited

5. DELETE:
   - Мягкое удаление (archived статус) или физическое?
   - Проверка: может ли быть удалено?

Требования:
- simple_form для всех форм
- Tailwind CSS таблицы и компоненты
- Валидации на обе стороны
- Авторизация (current_user)
- Полная интеграция Audited
- Error handling и flash messages
- Очень хороший UX

Предоставь:
- Контроллеры с комментариями
- Представления
- Маршруты
- Моделі Scopes для часто используемых фильтров (by_status, by_type и т.д.)
```

### ПРОМПТ #6: Поиск, фильтрация и сортировка с Ransack

```
Реализуй мощный поиск и фильтрацию для оборудования используя Ransack.

Требования:
1. Добавить gem 'ransack' для поиска
2. Для оборудования (CUTE и FIDS) реализовать фильтрацию по:
   - Типу оборудования
   - Модели (поиск по подстроке)
   - Инвентарному номеру
   - Серийному номеру
   - Статусу (multi-select)
   - Месту установки
   - Диапазону дат (от-до)
   - Примечанию (поиск по подстроке)

3. Реализовать сортировку по:
   - Названию (A-Z, Z-A)
   - Дате последнего действия (новые-старые, старые-новые)
   - Статусу
   - Месту установки

4. Form для фильтров:
   - Все фильтры на одной странице (в collapse или sidebar)
   - Кнопка "Применить фильтр"
   - Кнопка "Сбросить фильтры"
   - URL сохраняет фильтры (для сохранения при перезагрузке)

5. Результаты:
   - Количество найденных элементов
   - Пагинация результатов
   - Если нет результатов - вывести сообщение

Требования производительности:
- Для нескольких тысяч записей должно работать быстро
- Использовать includes для избежания N+1 запросов
- Индексы в БД

Предоставь:
- Обновления контроллеров
- Представления с Ransack формой
- Scopes в моделях для оптимизации
- Примеры использования
```

### ПРОМПТ #7: Экспорт данных в CSV и Excel

```
Реализуй экспорт данных оборудования в CSV и Excel форматы.

Требования:
1. Создать экспорт для оборудования (CUTE и FIDS отдельно)
2. Экспорт должен учитывать текущие фильтры (экспортировать только отфильтрованные результаты)
3. CSV экспорт:
   - Использовать встроенный CSV модуль Ruby
   - Колонки: ID, Тип, Модель, Инвентарный №, Серийный №, Статус, Место установки, Последнее действие, Примечание
   - Кодировка UTF-8 с BOM для правильного отображения в Excel (Windows)
   - Разделитель: точка с запятой (;)

4. Excel экспорт (.xlsx):
   - Использовать gem 'write_xlsx'
   - Одна страница = одна таблица
   - Форматирование: заголовки жирные, чередующиеся цвета строк
   - Автоширина колонок
   - Фильтры в заголовках
   - Отдельный лист для метаинформации (дата экспорта, количество записей)

5. Общее:
   - Кнопка экспорта на странице индекса (рядом с таблицей)
   - Выбор формата (CSV или Excel)
   - Диалог для подтверждения параметров экспорта
   - Безопасность: только авторизованные пользователи
   - Когда данных много (>1000 строк) показать прогресс

Предоставь:
- ExportsController
- Обновления контроллеров оборудования
- Представления для экспорта
- Маршруты
- Примеры форматирования
- Обработка ошибок
```

### ПРОМПТ #8: Главное меню и навигация

```
Создай главное меню приложения учёта оборудования.

Требования:
1. Главная страница (Dashboard) с меню:
   - Два основных раздела: CUTE, FIDS
   - Под каждым разделом:
     * Оборудование (ссылка на список оборудования)
     * Места установки (ссылка на места установки)

2. Боковая панель навигации (Sidebar):
   - Логотип/название приложения
   - Основные разделы (CUTE, FIDS)
   - Ссылка на Audit Logs
   - Ссылка на профиль пользователя
   - Кнопка выхода (Sign Out)

3. Верхняя навигационная панель (Header):
   - Текущий пользователь (email)
   - Меню пользователя (профиль, выход)
   - Дата/время (опционально)

4. Dashboard:
   - Статистика:
     * Количество оборудования CUTE (активного, в ремонте, архивированного)
     * Количество оборудования FIDS (по статусам)
     * Количество мест установки
   - Недавно добавленное оборудование (последние 5)
   - Недавние изменения (последние 10 из audit logs)
   - Quick links для быстрого добавления нового оборудования

5. Дизайн:
   - Tailwind CSS
   - Темная или светлая тема (опционально)
   - Responsive для десктопа (мобильность не требуется)
   - Иконки из heroicons gem

Предоставь:
- PagesController с dashboard action
- Представления pages/dashboard.html.erb
- Layouts с header и sidebar
- Частичные представления (_header, _sidebar, _stats)
- Маршруты
- CSS/Tailwind классы
```

### ПРОМПТ #9: API endpoints для интеграций

```
Создай RESTful API для приложения учёта оборудования для будущих интеграций.

Требования:
1. API версионирование: /api/v1/
2. Endpoints для оборудования:
   - GET /api/v1/cute_equipments (список с фильтрацией)
   - GET /api/v1/cute_equipments/:id (детали)
   - POST /api/v1/cute_equipments (создание)
   - PATCH /api/v1/cute_equipments/:id (обновление)
   - DELETE /api/v1/cute_equipments/:id (удаление)
   - Аналогично для FIDS и Installations

3. Фильтры API:
   - ?type=cpu (фильтр по типу)
   - ?status=active (фильтр по статусу)
   - ?installation_id=1 (фильтр по месту)
   - ?page=1&per_page=50 (пагинация)
   - ?sort=created_at (сортировка)

4. Ответы API:
   - JSON формат
   - Успех: { "data": {...}, "meta": {...} }
   - Ошибка: { "errors": [...] }
   - HTTP статус коды правильные (200, 201, 400, 401, 404, 500)

5. Аутентификация:
   - Token-based (можно использовать Devise token auth)
   - Каждый пользователь видит только свои данные
   - Rate limiting (опционально)

6. Документация:
   - Примеры запросов и ответов
   - Описание параметров
   - Ошибки и их коды

Используй:
- Rails 7.1 API mode для контроллеров
- Serializers (active_model_serializers)
- gem 'api-pagination' для единообразной пагинации

Предоставь:
- API контроллеры в app/controllers/api/v1/
- Serializers
- Маршруты (config/routes.rb)
- Примеры curl команд
- Документацию API
```

### ПРОМПТ #10: Тестирование с RSpec

```
Напиши RSpec тесты для Rails 7.1 приложения учёта оборудования.

Требования:
1. Unit тесты для моделей:
   - User модель (валидации, аутентификация)
   - CuteEquipment модель (валидации, associations, callbacks)
   - FidsInstallation модель (валидации)
   - Проверка enum статусов
   - Проверка associations

2. Feature тесты (integration):
   - Регистрация пользователя
   - Вход в систему
   - Создание оборудования
   - Редактирование оборудования
   - Удаление оборудования
   - Поиск и фильтрация
   - Экспорт в CSV
   - Просмотр audit logs

3. Controller тесты:
   - Авторизация (только owner видит свои данные)
   - Создание новой записи
   - Обновление
   - Удаление
   - Ошибки валидации

4. API тесты:
   - GET /api/v1/cute_equipments
   - POST /api/v1/cute_equipments
   - PATCH /api/v1/cute_equipments/:id
   - DELETE /api/v1/cute_equipments/:id

Требования:
- Coverage минимум 80%
- Factory Bot для fixtures
- Faker для генерации тестовых данных
- Shoulda-matchers для упрощения тестов
- Группировка тестов (describe блоки)
- Descriptive тест нейминг на английском
- Setup и teardown правильно

Используй:
- gem 'rspec-rails'
- gem 'factory_bot_rails'
- gem 'faker'
- gem 'shoulda-matchers'

Предоставь:
- Примеры тестов для каждой категории
- Factory definitions
- Конфигурация RSpec
- Команды запуска тестов
- Примеры coverage report
```

### ПРОМПТ #11: Миграция на PostgreSQL и оптимизация для production

```
Подготови приложение к миграции с SQLite на PostgreSQL и развёртыванию на production.

Требования:
1. Оптимизация для production:
   - Индексы для всех foreign keys
   - Индексы для часто используемых полей поиска
   - Индексы для сортировки
   - Индексы для range queries (дата)
   - Анализ производительности запросов

2. Миграция SQLite → PostgreSQL:
   - Скрипт для экспорта данных из SQLite
   - Скрипт для импорта в PostgreSQL
   - Проверка целостности данных
   - Миграция последовательностей

3. Configuration:
   - Обновление Gemfile для PostgreSQL
   - Конфигурация database.yml
   - Connection pooling
   - Параметры оптимизации PostgreSQL

4. Performance:
   - Query optimization
   - N+1 query elimination
   - Caching strategy (если нужна)
   - Batch operations для больших операций

5. Backup & Recovery:
   - Стратегия резервного копирования
   - Скрипты backup/restore
   - Проверка целостности

Предоставь:
- Миграции для production indices
- Скрипты миграции данных
- Обновленный Gemfile с pg gem
- Database.yml конфигурации
- Документация процесса миграции
- SQL queries для анализа перформанса
- Monitoring queries
```

### ПРОМПТ #12: Документация и подготовка к изолированной ВМ

```
Создай полную документацию приложения для развёртывания на изолированной виртуальной машине.

Структура документации:
1. README.md:
   - Описание приложения
   - Требования к системе
   - Быстрый старт

2. SETUP.md:
   - Пошаговая инструкция установки на новую машину
   - Требования (Ruby, Rails, PostgreSQL, Git)
   - Установка зависимостей
   - Инициализация БД
   - Загрузка seed данных

3. DEPLOYMENT.md:
   - Развёртывание на изолированной ВМ
   - Без доступа в интернет: подготовка зависимостей заранее
   - Configurация веб-сервера (Puma, Nginx)
   - SSL certificates
   - Systemd services
   - Firewall rules

4. DATABASE.md:
   - Схема БД
   - ER диаграмма
   - Миграции
   - Backup процедуры

5. API.md:
   - Полная документация API
   - Примеры запросов
   - Ошибки

6. TROUBLESHOOTING.md:
   - Частые ошибки и решения
   - Логирование
   - Debug режим

7. ARCHITECTURE.md:
   - Архитектура приложения
   - Описание моделей
   - Data flow диаграммы

8. DEVELOPMENT.md:
   - Git workflow
   - Commit messages conventions
   - Code style guide
   - Testing
   - CI/CD (если применимо)

Требования:
- Markdown формат
- Ясные инструкции
- Примеры команд
- Скрипты где возможно
- Предусмотрено для работы без интернета
- Русский и английский языки

Предоставь:
- Шаблоны всех документов
- Примеры кода
- Скрипты для автоматизации
```

### ПРОМПТ #13: Git workflow и коммиты

```
Определи Git workflow для разработки приложения с русскоязычными коммитами.

Требования:
1. Ветвления:
   - main: production-ready код
   - develop: интеграционная ветвь
   - feature/*: отдельные задачи
   - bugfix/*: исправления
   - docs/*: документация

2. Коммит-сообщения на русском:
   - Формат: [ТИП] Описание
   - Типы: feat, fix, docs, style, refactor, test, chore
   - Примеры:
     * "feat: добавлена аутентификация Devise"
     * "fix: исправлена сортировка оборудования"
     * "docs: добавлена инструкция по развёртыванию"
     * "test: написаны тесты для CuteEquipment"
     * "refactor: оптимизирован поиск с Ransack"

3. Pull Request процесс:
   - Создание PR из feature ветви в develop
   - Code review перед мержем
   - Запуск тестов
   - CI/CD проверки

4. Релизы:
   - Версионирование: semantic versioning (major.minor.patch)
   - Tag в git для релизов
   - Release notes

5. .gitignore:
   - Rails специфичные файлы
   - Secrets
   - Логи
   - Временные файлы
   - IDE файлы

Предоставь:
- .gitignore файл
- Инструкции по branching
- Шаблон PR description
- Примеры коммитов
- Скрипты для автоматизации workflow
- Pre-commit hooks (опционально)
```

### ПРОМПТ #14: Полная интеграция и checklist

```
Создай финальный checklist и интеграционные тесты для полного приложения.

Требования:
1. End-to-end сценарии:
   - Пользователь регистрируется
   - Добавляет места установки (CUTE и FIDS)
   - Добавляет оборудование в оба раздела
   - Редактирует оборудование
   - Ищет оборудование
   - Экспортирует данные в CSV и Excel
   - Просматривает audit logs
   - Выходит

2. Performance тесты:
   - Загрузка страницы со списком 5000+ оборудования
   - Поиск по 5000+ записям
   - Экспорт 5000+ записей
   - Одновременно 10 пользователей

3. Security тесты:
   - CSRF защита
   - SQL injection prevention
   - XSS prevention
   - Authorization checks

4. Compatibility тесты:
   - Versions compatibility matrix
   - Rails 7.1 ✓
   - Ruby 3.3 ✓
   - Все gems последних стабильных версий

5. Checklist перед production:
   - [ ] Все тесты проходят
   - [ ] Code coverage > 80%
   - [ ] Документация полная
   - [ ] Миграция на PostgreSQL протестирована
   - [ ] Backup процедуры работают
   - [ ] Логирование настроено
   - [ ] Errors tracking настроен (опционально)
   - [ ] Performance оптимизирована
   - [ ] Security audит пройден

Предоставь:
- Integration spec файлы (RSpec)
- Performance test скрипты
- Инструкции по запуску
- Checklist документ
```

### ПРОМПТ #15: Оптимизация и производительность

```
Оптимизируй Rails 8.0.4 приложение учёта оборудования для работы с несколькими тысячами записей.

Требования:
1. Database optimization:
   - Все индексы на месте
   - Foreign key индексы
   - Composite indices где нужно
   - Query optimization
   - Explain plan анализ

2. Rails optimization:
   - Eager loading (includes, preload, eager_load)
   - N+1 query elimination
   - View caching (fragment caching)
   - HTTP caching headers
   - Gzip compression

3. Поиск optimization:
   - Ransack с индексами
   - Full-text search если нужна
   - Кэширование поиска (redis опционально)

4. Пагинация:
   - Pagy вместо Kaminari
   - Опции: cursor-based pagination для больших наборов

5. Экспорт optimization:
   - Streaming экспорт для больших наборов
   - Background jobs для экспорта (Sidekiq опционально)
   - Progress tracking

6. Мониторинг:
   - Rails query logs
   - Bullet gem для N+1 detection
   - Performance gems

Предоставь:
- SQL индексы миграции
- Оптимизированные scopes
- Кэширование стратегию
- Query optimization примеры
- Мониторинг setup
- Performance dashboard (опционально)
- Benchmarking скрипты
```

---

## 📁 Git Workflow

### Инициализация репозитория

```bash
# Создание проекта
rails new equipment_management --database=sqlite3 --skip-javascript

# Инициализация git
cd equipment_management
git init
git config user.email "your.email@example.com"
git config user.name "Your Name"

# Создание удалённого репозитория и подключение
git remote add origin <repository-url>

# Начальный коммит
git add .
git commit -m "chore: инициализация Rails 7.1 проекта"
git push -u origin main
```

### Branching Strategy

```bash
# Основные ветви
main              # Production-ready код
develop           # Интеграционная ветвь

# Рабочие ветви
feature/auth      # Новая функция (от develop)
feature/cute-crud # CRUD для CUTE
bugfix/search     # Исправление ошибки (от develop)
docs/setup        # Обновление документации (от develop)

# Пример создания feature ветви
git checkout -b feature/devise-setup
# ... работа ...
git add .
git commit -m "feat: настройка Devise для аутентификации"
git push origin feature/devise-setup
# Создание Pull Request в develop
```

### Коммит-сообщения (на русском)

```
[feat]  - новая функция
[fix]   - исправление ошибки
[docs]  - документация
[test]  - тесты
[refactor] - рефакторинг
[perf]  - оптимизация производительности
[chore] - другое (зависимости, конфигурация)

Примеры:
feat: добавлена модель CuteEquipment с валидациями
fix: исправлена сортировка по дате в Ransack
docs: добавлена инструкция по установке на ВМ
test: написаны tests для API endpoints
refactor: оптимизирован N+1 query в index action
perf: добавлены индексы для полей поиска
chore: обновлены версии gems в Gemfile.lock
```

---

## 🚀 Развёртывание на изолированной ВМ

### Подготовка (на машине с интернетом)

```bash
# 1. Создание bundle для offline
bundle config set --local path vendor/bundle
bundle install --no-deploy

# 2. Создание gem кэша
mkdir -p vendor/gems-cache
cd vendor/gems-cache
bundle cache --all

# 3. Загрузка базовых зависимостей для ВМ
# - Ruby 3.3.0
# - PostgreSQL
# - Git
# Скачать установщики и положить в отдельную папку
```

### Развёртывание на ВМ (без интернета)

```bash
# 1. Установка Ruby 3.3.0 (из offline installer)
# 2. Установка PostgreSQL
# 3. Установка Git
# 4. Копирование проекта на ВМ

# 5. Установка зависимостей из кэша
cd /path/to/app
bundle config set --local path vendor/bundle
bundle install --local --no-deploy

# 6. Инициализация БД
rails db:create
rails db:migrate
rails db:seed

# 7. Компиляция assets
rails assets:precompile

# 8. Создание systemd service для Puma
# (см. документацию DEPLOYMENT.md)

# 9. Настройка Nginx
# (см. конфигурацию в docs/)

# 10. Запуск приложения
systemctl start rails-app
```

---

## ✓ Чек-лист проверки версий

### Compatibility Matrix

| Компонент | Версия | Статус | Альтернатива |
|-----------|--------|--------|-------------|
| Ruby | 3.3.0+ | ✓ Stable | 3.2.x (старше) |
| Rails | 7.1.x | ✓ LTS | 7.0.x (старше) |
| SQLite | 1.7+ | ✓ Stable | - |
| PostgreSQL | 13+ | ✓ Stable | 12.x (при миграции) |
| Devise | 4.9.x | ✓ Stable | 4.8.x |
| Ransack | 4.1.x | ✓ Stable | 4.0.x |
| Tailwind CSS | 3.4+ | ✓ Stable | 3.3.x |
| Pundit | 2.3.x | ✓ Stable | 2.2.x |
| Pagy | 7.2+ | ✓ Stable | 7.1.x |
| Audited | 5.3.x | ✓ Stable | 5.2.x |
| Simple Form | 5.3+ | ✓ Stable | 5.2.x |
| RSpec Rails | 6.1+ | ✓ Stable | 6.0.x |
| Faker | 3.2+ | ✓ Stable | 3.1.x |

### Pre-Development Checks

```bash
# 1. Версии установленных инструментов
ruby -v        # Должна быть 3.3.0+
rails -v       # Должна быть 7.1.x
bundler -v     # Должна быть 2.4.x+
node -v        # Опционально, для фронте-энда
yarn -v        # Опционально

# 2. Проверка Gemfile.lock
# Убедиться что все gems имеют последние patch версии

# 3. Проверка совместимости сразу после создания проекта
bundle audit   # Проверка на уязвимости

# 4. Тестирование локально перед развёртыванием
rails test
rspec
bundle exec rubocop
```

### Production Checks (Перед развёртыванием)

```bash
# 1. Database
rake db:structure:dump
rake db:test:prepare

# 2. Assets
rails assets:precompile
rails assets:clobber

# 3. Security
bundle audit update
bundle audit

# 4. Performance
bundle exec bullet

# 5. Code quality
bundle exec rubocop
bundle exec rails_best_practices

# 6. Tests
bundle exec rspec
bundle exec rspec --profile
```

---

## 📚 Структура папок документации

```
docs/
├── README.md                    # Основная документация
├── SETUP.md                     # Инструкция установки
├── DEPLOYMENT.md                # Развёртывание
├── DATABASE.md                  # Схема БД
├── API.md                       # Документация API
├── ARCHITECTURE.md              # Архитектура
├── TROUBLESHOOTING.md           # Решение проблем
├── DEVELOPMENT.md               # Гайд разработчика
├── GIT_WORKFLOW.md              # Git процесс
├── MODELS_SCHEMA.md             # Диаграмма моделей
├── PERFORMANCE.md               # Оптимизация
├── BACKUP_RECOVERY.md           # Резервное копирование
├── SECURITY.md                  # Security гайд
├── TESTING.md                   # Гайд по тестированию
└── ROADMAP.md                   # План развития
```

---

## 🎯 Итоговый путь разработки

### Неделя 1: Фундамент
1. Инициализация проекта (Промпт #1)
2. Models и Database (Промпт #2)
3. Devise аутентификация (встроено в Промпт #1)
4. Первые миграции и seeds

### Неделя 2: CRUD операции
1. Места установки (Промпт #4)
2. Оборудование CUTE (Промпт #5)
3. Оборудование FIDS (дублирование CUTE)
4. Базовое тестирование

### Неделя 3: Функциональность
1. Audit логирование (Промпт #3)
2. Поиск и фильтрация (Промпт #6)
3. Экспорт в CSV/Excel (Промпт #7)
4. Интеграционные тесты

### Неделя 4: Завершение
1. Dashboard и навигация (Промпт #8)
2. API endpoints (Промпт #9)
3. Полное тестирование (Промпт #10)
4. Документация (Промпт #12)

### Неделя 5: Production
1. Миграция на PostgreSQL (Промпт #11)
2. Оптимизация (Промпт #15)
3. Performance тестирование (Промпт #14)
4. Развёртывание на ВМ

---

## 📞 Контакты для поддержки

- Документация: `/docs/`
- Issues: GitHub Issues
- Комментарии в коде на русском
- Коммиты на русском

---

**Дата обновления плана:** 21 января 2026  
**Версия плана:** 1.0  
**Статус:** Готово к реализации
