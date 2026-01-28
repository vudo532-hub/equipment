# Краткое руководство: Единая система модальных окон оборудования

## Что было реализовано?

Универсальная система модальных окон для добавления и редактирования оборудования во всех трёх системах (CUTE, FIDS, ZAMAR).

## Ключевые преимущества

✅ **Один Turbo Frame** для всех трёх систем (`equipment-modal-frame`)
✅ **Одна форма** используется динамически для всех систем  
✅ **Автоматическое открытие** модального окна при загрузке контента  
✅ **Динамические заголовки** с названием системы и моделью оборудования  
✅ **Улучшенная обработка ошибок** с перезагрузкой формы  
✅ **Масштабируемая архитектура** для добавления новых систем

## Быстрый старт

### 1. Добавление оборудования

```erb
<%= link_to new_cute_equipment_path,
    class: "btn btn-primary",
    data: { turbo_frame: "equipment-modal-frame" } do %>
  Добавить оборудование
<% end %>
```

### 2. Редактирование оборудования

```erb
<%= link_to edit_cute_equipment_path(equipment),
    data: { turbo_frame: "equipment-modal-frame" },
    class: "btn btn-sm btn-outline" do %>
  Редактировать
<% end %>
```

### 3. Автоматическое переключение между системами

Система работает автоматически:
- Кликаешь "Добавить" в CUTE → открывается CUTE форма
- Не закрывая модаль, кликаешь "Добавить" в FIDS → переключается на FIDS форму
- Данные CUTE автоматически очищаются

## Структура файлов

```
app/
├── views/shared/
│   ├── _equipment_modal.html.erb          ← Контейнер модального окна
│   └── _equipment_modal_form.html.erb     ← Общая форма для всех систем
├── helpers/
│   └── equipment_modal_helper.rb          ← Helpers для динамики
├── controllers/
│   ├── cute_equipments_controller.rb      ← Обновлён
│   ├── fids_equipments_controller.rb      ← Обновлён
│   └── zamar_equipments_controller.rb     ← Обновлён
├── javascript/controllers/
│   └── modal_controller.js                ← Улучшен
└── views/layouts/
    └── application.html.erb               ← Уже содержит модаль

docs/
└── UNIFIED_MODAL_SYSTEM.md                ← Полная документация
```

## API Helpers

### В views:

```erb
<!-- Заголовок модального окна -->
<%= equipment.persisted? ? 
    modal_title_for_edit(equipment, equipment_type) : 
    modal_title_for_new(equipment_type) %>

<!-- Путь формы (автоматический выбор) -->
<%= form_with(model: equipment, url: form_path_for_equipment(equipment, equipment_type)) %>

<!-- Ссылка для добавления -->
<%= add_equipment_modal_link('cute') { 'Добавить CUTE' } %>

<!-- Ссылка для редактирования -->
<%= edit_equipment_modal_link(equipment, 'cute') { 'Редактировать' } %>
```

## Обработка ошибок

При ошибке валидации:
1. Контроллер возвращает форму с ошибками
2. Форма перезагружается в модальном окне
3. Пользователь видит сообщение об ошибке
4. Может исправить и отправить снова

Пример в контроллере:
```ruby
format.turbo_stream do
  render turbo_stream: turbo_stream.replace(
    "equipment-modal-frame",
    partial: "shared/equipment_modal_form",
    locals: { equipment: @equipment, equipment_type: @equipment_type, installations: @installations }
  ), status: :unprocessable_entity  # ← Статус ошибки
end
```

## Добавление новой системы (например, AIRPORT)

1. Создайте контроллер `AirportEquipmentsController` (копируйте из CUTE)
2. Обновите `equipment_modal_helper.rb`:

```ruby
def equipment_system_name(type)
  case type
  # ... существующие case ...
  when 'airport'
    'AIRPORT'
  end
end

def form_path_for_equipment(equipment, type)
  case type
  # ... существующие case ...
  when 'airport'
    equipment.persisted? ? airport_equipment_path(equipment) : airport_equipments_path
  end
end
```

3. Используйте `@equipment_type = 'airport'` в новом контроллере

Всё! Модальная система будет работать автоматически.

## Отладка

### Проверка, загружается ли форма

1. Откройте DevTools (F12)
2. Перейдите на Network вкладку
3. Кликните "Добавить оборудование"
4. Проверьте, что запрос идёт на `/cute_equipments/new`
5. Ответ должен содержать `<turbo-frame id="equipment-modal-frame">`

### Проверка Stimulus контроллера

В консоли:
```javascript
// Найдите модальное окно
const modal = document.getElementById('equipment-modal')

// Вызовите open вручную (если нужно отладить)
const controller = modal.__stimulus_instance_3
controller.open()

// Или close
controller.close()
```

### Частые проблемы

| Проблема | Решение |
|----------|----------|
| Модаль не открывается | Проверьте `data: { turbo_frame: "equipment-modal-frame" }` на ссылке |
| Форма не отправляется | Проверьте параметры в `equipment_params` контроллера |
| Ошибки не показываются | Убедитесь, что используется `shared/_equipment_modal_form.html.erb` |
| Модаль закрывается без сохранения | Проверьте, что `status: :unprocessable_entity` установлен при ошибке |

## Производительность

- **Ленивая загрузка**: Модальное окно загружается только когда нужно
- **Кэширование**: Turbo автоматически кэширует ответы
- **Минимальная передача данных**: Только необходимый HTML отправляется

## Безопасность

- CSRF защита через Rails встроенные механизмы
- Аутентификация через `before_action :authenticate_user!`
- Авторизация через `before_action :require_delete_permission, only: [:destroy]`
- HTML escaping автоматический (Turbo Stream)

## Тестирование совместимости

**Сценарий 1: Добавление CUTE**
1. Кликните "Добавить" в таблице CUTE
2. Заполните форму
3. Кликните "Добавить оборудование"
4. ✓ Оборудование добавилось, модаль закрылась

**Сценарий 2: Переключение между системами**
1. Кликните "Добавить" в CUTE (откроется CUTE форма)
2. Не закрывая, кликните "Добавить" в FIDS
3. ✓ Модаль переключилась на FIDS форму
4. Заполните FIDS форму и отправьте
5. ✓ FIDS оборудование добавилось

**Сценарий 3: Редактирование**
1. В таблице кликните кнопку редактирования
2. ✓ Модаль откроется с заполненной формой
3. Измените данные
4. Кликните "Сохранить изменения"
5. ✓ Оборудование обновилось, модаль закрылась

## Полная документация

Детальное описание архитектуры, примеры кода и advanced использование:
→ Смотрите `docs/UNIFIED_MODAL_SYSTEM.md`

## Полезные ссылки

- [Hotwired Turbo](https://turbo.hotwired.dev/)
- [Stimulus JS](https://stimulus.hotwired.dev/)
- [Rails Turbo Cable](https://guides.rubyonrails.org/action_cable_overview.html)

## Проблемы или вопросы?

1. Проверьте консоль браузера (F12 → Console)
2. Проверьте server logs (терминал с Rails)
3. Смотрите Network вкладку для отладки запросов
4. Смотрите `docs/UNIFIED_MODAL_SYSTEM.md` для детальных примеров
