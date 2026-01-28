# Единая система модальных окон оборудования

## Обзор решения

Это решение обеспечивает единую систему модальных окон для добавления и редактирования оборудования во всех трёх системах (CUTE, FIDS, ZAMAR). Система использует:

- **Один Turbo Frame** (`equipment-modal-frame`) для всех систем
- **Один Stimulus контроллер** для управления открытием/закрытием модального окна
- **Одна общая форма** в `shared/_equipment_modal_form.html.erb`
- **Динамические заголовки и пути** в зависимости от типа оборудования

## Архитектура

```
app/
├── views/
│   ├── shared/
│   │   ├── _equipment_modal.html.erb          # Контейнер модального окна (один для всех)
│   │   └── _equipment_modal_form.html.erb     # Форма (один для всех с динамикой)
│   ├── cute_equipments/
│   │   ├── index.html.erb                     # Таблица CUTE
│   │   ├── new.html.erb                       # Страница new (редко используется)
│   │   ├── edit.html.erb                      # Страница edit (редко используется)
│   │   └── show.html.erb                      # Детали оборудования
│   ├── fids_equipments/
│   └── zamar_equipments/
├── controllers/
│   ├── cute_equipments_controller.rb          # Обновлено для использования universal form
│   ├── fids_equipments_controller.rb          # Нужно обновить (см. примеры ниже)
│   └── zamar_equipments_controller.rb         # Нужно обновить (см. примеры ниже)
├── helpers/
│   └── equipment_modal_helper.rb              # Helpers для работы с модалями
├── javascript/
│   └── controllers/
│       └── modal_controller.js                # Stimulus контроллер
└── views/
    └── layouts/
        └── application.html.erb               # Уже содержит <%= render "shared/equipment_modal" %>
```

## Как это работает

### 1. Открытие модального окна

Когда пользователь кликает на кнопку "Добавить оборудование":

```erb
<%= link_to new_cute_equipment_path,
    class: "...",
    data: { turbo_frame: "equipment-modal-frame" } do %>
  Добавить оборудование
<% end %>
```

Turbo загружает ответ контроллера в `equipment-modal-frame` Turbo Frame.

### 2. Контроллер обрабатывает запрос

В контроллере `new` действие:

```ruby
def new
  @equipment = CuteEquipment.new
  @installations = CuteInstallation.ordered
  @equipment_type = 'cute'

  respond_to do |format|
    format.html                    # для обычного браузера
    format.turbo_stream do         # для Turbo запроса
      render turbo_stream: turbo_stream.replace(
        "equipment-modal-frame",
        partial: "shared/equipment_modal_form",
        locals: { equipment: @equipment, equipment_type: @equipment_type, installations: @installations }
      )
    end
  end
end
```

### 3. Форма автоматически адаптируется

В `shared/_equipment_modal_form.html.erb` используются helpers:

```erb
<h2><%= equipment.persisted? ? modal_title_for_edit(equipment, equipment_type) : modal_title_for_new(equipment_type) %></h2>

<%= form_with(model: equipment, url: form_path_for_equipment(equipment, equipment_type)) %>
  ...
</form>
```

Helpers из `equipment_modal_helper.rb` автоматически выбирают правильный путь:
- Для CUTE: `cute_equipment_path` или `cute_equipments_path`
- Для FIDS: `fids_equipment_path` или `fids_equipments_path`
- Для ZAMAR: `zamar_equipment_path` или `zamar_equipments_path`

### 4. Stimulus контроллер управляет видимостью

```javascript
// modal_controller.js - автоматически открывает модаль при загрузке содержимого
observeFrameChanges() {
  const frame = document.querySelector("turbo-frame#equipment-modal-frame")
  if (frame) {
    frame.addEventListener("turbo:load", () => this.open())
  }
}
```

## Обновление FIDS и ZAMAR контроллеров

Примеры того, как обновить другие контроллеры:

### app/controllers/fids_equipments_controller.rb

```ruby
class FidsEquipmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_equipment, only: [:show, :edit, :update, :destroy, :assign_to_installation, :unassign_from_installation, :audit_history]
  before_action :require_delete_permission, only: [:destroy]

  # ... другие actions ...

  def new
    @equipment = FidsEquipment.new
    @equipment.fids_installation_id = params[:fids_installation_id] if params[:fids_installation_id].present?
    @installations = FidsInstallation.ordered
    @equipment_type = 'fids'  # ← Ключевое отличие: тип оборудования

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "equipment-modal-frame",
          partial: "shared/equipment_modal_form",
          locals: { equipment: @equipment, equipment_type: @equipment_type, installations: @installations }
        )
      end
    end
  end

  def create
    @equipment = FidsEquipment.new(equipment_params)
    @equipment.user = current_user
    @equipment.last_changed_by = current_user
    @equipment_type = 'fids'

    if @equipment.save
      respond_to do |format|
        format.html do
          redirect_to fids_equipments_path, notice: t("flash.created", resource: FidsEquipment.model_name.human)
        end
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("equipment-modal-frame", ""),
            turbo_stream.append("equipment-table-body",
              partial: "shared/equipment_row",
              locals: { equipment: @equipment, equipment_type: "fids" }
            ) if turbo_request_from_modal?,
            turbo_stream.replace("flash-messages",
              partial: "shared/flash_message",
              locals: { message: t("flash.created", resource: FidsEquipment.model_name.human), type: "success" }
            )
          ].compact
        end
      end
    else
      @installations = FidsInstallation.ordered
      respond_to do |format|
        format.html do
          render :new, status: :unprocessable_entity
        end
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "equipment-modal-frame",
            partial: "shared/equipment_modal_form",
            locals: { equipment: @equipment, equipment_type: @equipment_type, installations: @installations }
          ), status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    @installations = FidsInstallation.ordered
    @equipment_type = 'fids'

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "equipment-modal-frame",
          partial: "shared/equipment_modal_form",
          locals: { equipment: @equipment, equipment_type: @equipment_type, installations: @installations }
        )
      end
    end
  end

  def update
    @equipment.last_changed_by = current_user
    @equipment.current_user_admin = current_user.admin?
    @equipment_type = 'fids'

    if @equipment.update(equipment_params)
      respond_to do |format|
        format.html do
          if params[:from] == 'show'
            redirect_to fids_equipment_path(@equipment), notice: t("flash.updated", resource: FidsEquipment.model_name.human)
          else
            redirect_to fids_equipments_path, notice: t("flash.updated", resource: FidsEquipment.model_name.human)
          end
        end
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("equipment-modal-frame", ""),
            turbo_stream.replace("equipment-row-#{@equipment.id}",
              partial: "shared/equipment_row",
              locals: { equipment: @equipment, equipment_type: "fids" }
            ) if turbo_request_from_modal?,
            turbo_stream.replace("flash-messages",
              partial: "shared/flash_message",
              locals: { message: t("flash.updated", resource: FidsEquipment.model_name.human), type: "success" }
            )
          ].compact
        end
      end
    else
      @installations = FidsInstallation.ordered
      respond_to do |format|
        format.html do
          render :edit, status: :unprocessable_entity
        end
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "equipment-modal-frame",
            partial: "shared/equipment_modal_form",
            locals: { equipment: @equipment, equipment_type: @equipment_type, installations: @installations }
          ), status: :unprocessable_entity
        end
      end
    end
  end

  private

  def set_equipment
    @equipment = FidsEquipment.find(params[:id])
  end

  def equipment_params
    params.require(:fids_equipment).permit(
      :name, :equipment_type, :equipment_model, :serial_number,
      :inventory_number, :status, :note, :fids_installation_id
    )
  end

  def turbo_request_from_modal?
    request.headers['Turbo-Frame'] == 'equipment-modal-frame'
  end
end
```

### app/controllers/zamar_equipments_controller.rb

Аналогично FIDS, но заменить:
- `FidsEquipment` → `ZamarEquipment`
- `FidsInstallation` → `ZamarInstallation`
- `fids_equipment` → `zamar_equipment`
- `fids_installation` → `zamar_installation`
- `'fids'` → `'zamar'`

## Примеры в Views

### Кнопка "Добавить оборудование" (index.html.erb)

```erb
<%= link_to new_cute_equipment_path,
    class: "inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700",
    data: { turbo_frame: "equipment-modal-frame" } do %>
  <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
  </svg>
  Добавить оборудование
<% end %>
```

### Кнопка "Редактировать" в таблице (index.html.erb)

```erb
<%= link_to edit_cute_equipment_path(equipment),
    data: { turbo_frame: "equipment-modal-frame" },
    class: "text-indigo-600 hover:text-indigo-900 mr-4" do %>
  <svg class="w-4 h-4 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
  </svg>
<% end %>
```

### Кнопка "Редактировать" на странице детальной информации (show.html.erb)

```erb
<%= link_to edit_cute_equipment_path(@equipment),
    data: { turbo_frame: "equipment-modal-frame" },
    class: "inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700" do %>
  <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
  </svg>
  Редактировать
<% end %>
```

## Использование Helpers

### Генерация заголовка модального окна

```erb
<h2>
  <%= equipment.persisted? ? 
      modal_title_for_edit(equipment, equipment_type) : 
      modal_title_for_new(equipment_type) %>
</h2>
```

Выведет:
- Для добавления CUTE: "Добавить новое оборудование (CUTE)"
- Для редактирования CUTE: "Редактировать CUTE оборудование: Zebra ZD421"

### Получение пути формы

```erb
<%= form_with(model: equipment, url: form_path_for_equipment(equipment, equipment_type)) %>
```

Автоматически выберет правильный путь на основе типа оборудования.

## Обработка ошибок

Если при отправке формы произойдёт ошибка валидации:

1. Контроллер возвращает `status: :unprocessable_entity`
2. Форма повторно загружается с ошибками
3. Пользователь видит сообщение об ошибке в модальном окне
4. Может исправить и отправить снова

```ruby
format.turbo_stream do
  render turbo_stream: turbo_stream.replace(
    "equipment-modal-frame",
    partial: "shared/equipment_modal_form",
    locals: { equipment: @equipment, equipment_type: @equipment_type, installations: @installations }
  ), status: :unprocessable_entity
end
```

## Flash сообщения

После успешного создания/обновления модальное окно закрывается и показывается flash-сообщение:

```ruby
turbo_stream.replace("flash-messages",
  partial: "shared/flash_message",
  locals: { message: t("flash.created", resource: CuteEquipment.model_name.human), type: "success" }
)
```

Убедитесь, что у вас есть:
- `app/views/shared/_flash_message.html.erb` для отображения flash сообщений
- ID `equipment-modal-frame` в модальном окне для правильной замены

## Масштабирование на 4-ю систему

Если нужно добавить 4-ю систему (например, AIRPORT):

1. **Создайте контроллер**: `AirportEquipmentsController` (скопируйте из CUTE)
2. **Обновите helpers**: Добавьте случай для 'airport' в `equipment_modal_helper.rb`
3. **Используйте ту же форму**: `shared/equipment_modal_form.html.erb` работает для любого типа

```ruby
# equipment_modal_helper.rb
def equipment_system_name(type)
  case type
  when 'cute'
    'CUTE'
  when 'fids'
    'FIDS'
  when 'zamar'
    'ZAMAR'
  when 'airport'        # ← Добавить новый тип
    'AIRPORT'
  else
    'Оборудование'
  end
end

def form_path_for_equipment(equipment, type)
  case type
  # ... существующие cases ...
  when 'airport'        # ← Добавить новый тип
    equipment.persisted? ? airport_equipment_path(equipment) : airport_equipments_path
  end
end
```

## Отладка

### Проверка, загружается ли форма

Откройте DevTools (F12) и проверьте Network вкладку:
- Запрос должен идти на `/cute_equipments/new` или `/cute_equipments/:id/edit`
- Ответ должен содержать Turbo Frame с id="equipment-modal-frame"
- Header должен содержать `Turbo-Frame: equipment-modal-frame`

### Проверка Stimulus контроллера

В консоли DevTools:
```javascript
// Найдите элемент модального окна
const modal = document.getElementById('equipment-modal')

// Проверьте, есть ли controller
console.log(modal._stimulus_modules)

// Вызовите open вручную
document.querySelector('[data-controller="modal"]').__stimulus_instance_3.open()
```

### Common Issues

1. **Модальное окно не открывается**
   - Проверьте, что `data: { turbo_frame: "equipment-modal-frame" }` на ссылке
   - Проверьте, что контроллер возвращает `format.turbo_stream`

2. **Форма не отправляется**
   - Проверьте параметры в `equipment_params`
   - Убедитесь, что используется правильный путь (`form_path_for_equipment`)

3. **Модальное окно закрывается, но форма не очищается**
   - Проверьте, что `turbo_stream.replace("equipment-modal-frame", "")` выполняется после сохранения

## Лучшие практики

1. **Всегда используйте `@equipment_type`** в контроллере для последовательности
2. **Проверяйте `turbo_request_from_modal?`** перед добавлением в таблицу
3. **Используйте одну форму** (`shared/equipment_modal_form.html.erb`) для всех систем
4. **Не дублируйте ссылки** — используйте `data: { turbo_frame: "equipment-modal-frame" }`
5. **Тестируйте переключение систем** — открыть CUTE, не закрывая, открыть FIDS

## Дополнительные ресурсы

- [Hotwired Turbo Documentation](https://turbo.hotwired.dev/)
- [Stimulus JS Documentation](https://stimulus.hotwired.dev/)
- [Rails Form Helpers](https://guides.rubyonrails.org/form_helpers.html)
