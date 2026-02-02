# Промпты для Claude Opus 4.5
## Доработки системы учёта оборудования
**Rails 8.0.4 + Turbo + Stimulus**

**Дата:** 2 февраля 2026  
**Версия:** 7.0  
**Статус:** ✅ Готово к выполнению  
**Оптимизация:** ⚡ Производительность (без анимаций, batch inserts, кэширование)

---

## 📋 ОБЩАЯ СТРУКТУРА ДОРАБОТОК

### Последовательность выполнения:

1. **ПРОМПТ #9** — Управление типами оборудования и мест установки (админ-панель)
2. **ПРОМПТ #15** — Обновление типов оборудования CUTE/FIDS/Zamar
3. **ПРОМПТ #11** — Модальные окна для добавления/редактирования мест установки
4. **ПРОМПТ #10** — История установки оборудования в карточке места установки
5. **ПРОМПТ #12** — Импорт оборудования из Excel/CSV файлов
6. **ПРОМПТ #13** — Улучшение отображения audit_logs (человекопонятный язык)
7. **ПРОМПТ #14** — Пагинация для больших списков + тестовые данные

---

## ПРОМПТ #9: Управление типами оборудования и мест установки (админ-панель)

### Требования

В Rails 8.0.4 приложении учёта оборудования нужно создать централизованную систему управления типами оборудования и типами мест установки для всех трёх систем (CUTE, FIDS, ZAMAR).

### Текущая ситуация
- Типы оборудования и типы мест установки хранятся как enum в моделях
- Каждая система (CUTE, FIDS, ZAMAR) имеет свои уникальные типы
- Формы добавления/редактирования используют разные списки
- Нет централизованного управления этими списками

### Решение

#### 1. Создать две новые модели для хранения типов

**EquipmentType:**
```ruby
# app/models/equipment_type.rb
class EquipmentType < ApplicationRecord
  validates :system, presence: true, inclusion: { in: %w(cute fids zamar) }
  validates :name, :code, presence: true
  validates :name, uniqueness: { scope: :system }
  validates :code, uniqueness: { scope: :system }
  
  has_many :cute_equipments, foreign_key: 'equipment_type_id'
  has_many :fids_equipments, foreign_key: 'equipment_type_id'
  has_many :zamar_equipments, foreign_key: 'equipment_type_id'
  
  scope :active, -> { where(active: true) }
  scope :by_system, ->(system) { where(system: system) }
  
  def equipment_count
    case system
    when 'cute'
      CuteEquipment.where(equipment_type_id: id).count
    when 'fids'
      FidsEquipment.where(equipment_type_id: id).count
    when 'zamar'
      ZamarEquipment.where(equipment_type_id: id).count
    end
  end
end
```

**InstallationType:**
```ruby
# app/models/installation_type.rb
class InstallationType < ApplicationRecord
  validates :system, presence: true, inclusion: { in: %w(cute fids zamar) }
  validates :name, :code, presence: true
  validates :name, uniqueness: { scope: :system }
  validates :code, uniqueness: { scope: :system }
  
  has_many :cute_installations, foreign_key: 'installation_type_id'
  has_many :fids_installations, foreign_key: 'installation_type_id'
  has_many :zamar_installations, foreign_key: 'installation_type_id'
  
  scope :active, -> { where(active: true) }
  scope :by_system, ->(system) { where(system: system) }
  
  def installation_count
    case system
    when 'cute'
      CuteInstallation.where(installation_type_id: id).count
    when 'fids'
      FidsInstallation.where(installation_type_id: id).count
    when 'zamar'
      ZamarInstallation.where(installation_type_id: id).count
    end
  end
end
```

#### 2. Миграции

```ruby
# db/migrate/[timestamp]_create_equipment_types.rb
class CreateEquipmentTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :equipment_types do |t|
      t.string :system, null: false
      t.string :name, null: false
      t.string :code, null: false
      t.integer :position, default: 0
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :equipment_types, [:system, :code], unique: true
    add_index :equipment_types, [:system, :name], unique: true
    add_index :equipment_types, [:system, :active]
  end
end

# db/migrate/[timestamp]_create_installation_types.rb
class CreateInstallationTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :installation_types do |t|
      t.string :system, null: false
      t.string :name, null: false
      t.string :code, null: false
      t.integer :position, default: 0
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :installation_types, [:system, :code], unique: true
    add_index :installation_types, [:system, :name], unique: true
    add_index :installation_types, [:system, :active]
  end
end

# db/migrate/[timestamp]_add_equipment_type_to_equipments.rb
class AddEquipmentTypeToEquipments < ActiveRecord::Migration[8.0]
  def change
    add_column :cute_equipments, :equipment_type_id, :integer
    add_column :fids_equipments, :equipment_type_id, :integer
    add_column :zamar_equipments, :equipment_type_id, :integer
    
    add_foreign_key :cute_equipments, :equipment_types
    add_foreign_key :fids_equipments, :equipment_types
    add_foreign_key :zamar_equipments, :equipment_types
    
    add_index :cute_equipments, :equipment_type_id
    add_index :fids_equipments, :equipment_type_id
    add_index :zamar_equipments, :equipment_type_id
  end
end

# db/migrate/[timestamp]_add_installation_type_to_installations.rb
class AddInstallationTypeToInstallations < ActiveRecord::Migration[8.0]
  def change
    add_column :cute_installations, :installation_type_id, :integer
    add_column :fids_installations, :installation_type_id, :integer
    add_column :zamar_installations, :installation_type_id, :integer
    
    add_foreign_key :cute_installations, :installation_types
    add_foreign_key :fids_installations, :installation_types
    add_foreign_key :zamar_installations, :installation_types
    
    add_index :cute_installations, :installation_type_id
    add_index :fids_installations, :installation_type_id
    add_index :zamar_installations, :installation_type_id
  end
end
```

#### 3. Обновить модели оборудования

```ruby
# app/models/cute_equipment.rb
class CuteEquipment < ApplicationRecord
  belongs_to :equipment_type, optional: true
  belongs_to :installation, class_name: 'CuteInstallation', optional: true
  
  def equipment_type_name
    equipment_type&.name || "Неизвестно"
  end
end

# app/models/fids_equipment.rb
class FidsEquipment < ApplicationRecord
  belongs_to :equipment_type, optional: true
  belongs_to :installation, class_name: 'FidsInstallation', optional: true
  
  def equipment_type_name
    equipment_type&.name || "Неизвестно"
  end
end

# app/models/zamar_equipment.rb
class ZamarEquipment < ApplicationRecord
  belongs_to :equipment_type, optional: true
  belongs_to :installation, class_name: 'ZamarInstallation', optional: true
  
  def equipment_type_name
    equipment_type&.name || "Неизвестно"
  end
end
```

#### 4. Обновить модели мест установки

```ruby
# app/models/cute_installation.rb
class CuteInstallation < ApplicationRecord
  belongs_to :installation_type, optional: true
  has_many :equipments, class_name: 'CuteEquipment'
  
  def installation_type_name
    installation_type&.name || "Неизвестно"
  end
end

# app/models/fids_installation.rb
class FidsInstallation < ApplicationRecord
  belongs_to :installation_type, optional: true
  has_many :equipments, class_name: 'FidsEquipment'
  
  def installation_type_name
    installation_type&.name || "Неизвестно"
  end
end

# app/models/zamar_installation.rb
class ZamarInstallation < ApplicationRecord
  belongs_to :installation_type, optional: true
  has_many :equipments, class_name: 'ZamarEquipment'
  
  def installation_type_name
    installation_type&.name || "Неизвестно"
  end
end
```

#### 5. Админ-контроллеры

```ruby
# app/controllers/admin/equipment_types_controller.rb
class Admin::EquipmentTypesController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_equipment_type, only: [:edit, :update, :destroy]
  
  def index
    @system = params[:system] || 'cute'
    @equipment_types = EquipmentType.where(system: @system).order(:position)
  end
  
  def new
    @equipment_type = EquipmentType.new
    @systems = ['cute', 'fids', 'zamar']
  end
  
  def create
    @equipment_type = EquipmentType.new(equipment_type_params)
    
    if @equipment_type.save
      redirect_to admin_equipment_types_path(system: @equipment_type.system),
                  notice: 'Тип оборудования добавлен'
    else
      render :new
    end
  end
  
  def edit
    @systems = ['cute', 'fids', 'zamar']
  end
  
  def update
    if @equipment_type.update(equipment_type_params)
      redirect_to admin_equipment_types_path(system: @equipment_type.system),
                  notice: 'Тип оборудования обновлён'
    else
      render :edit
    end
  end
  
  def destroy
    system = @equipment_type.system
    
    if @equipment_type.equipment_count > 0
      redirect_to admin_equipment_types_path(system: system),
                  alert: "Невозможно удалить: используется в #{@equipment_type.equipment_count} записях"
    else
      @equipment_type.destroy
      redirect_to admin_equipment_types_path(system: system),
                  notice: 'Тип оборудования удалён'
    end
  end
  
  def reorder
    params[:equipment_types].each_with_index do |id, index|
      EquipmentType.find(id).update(position: index)
    end
    
    head :ok
  end
  
  private
  
  def set_equipment_type
    @equipment_type = EquipmentType.find(params[:id])
  end
  
  def equipment_type_params
    params.require(:equipment_type).permit(:system, :name, :code, :active)
  end
end

# app/controllers/admin/installation_types_controller.rb
class Admin::InstallationTypesController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_installation_type, only: [:edit, :update, :destroy]
  
  def index
    @system = params[:system] || 'cute'
    @installation_types = InstallationType.where(system: @system).order(:position)
  end
  
  def new
    @installation_type = InstallationType.new
    @systems = ['cute', 'fids', 'zamar']
  end
  
  def create
    @installation_type = InstallationType.new(installation_type_params)
    
    if @installation_type.save
      redirect_to admin_installation_types_path(system: @installation_type.system),
                  notice: 'Тип места установки добавлен'
    else
      render :new
    end
  end
  
  def edit
    @systems = ['cute', 'fids', 'zamar']
  end
  
  def update
    if @installation_type.update(installation_type_params)
      redirect_to admin_installation_types_path(system: @installation_type.system),
                  notice: 'Тип места установки обновлён'
    else
      render :edit
    end
  end
  
  def destroy
    system = @installation_type.system
    
    if @installation_type.installation_count > 0
      redirect_to admin_installation_types_path(system: system),
                  alert: "Невозможно удалить: используется в #{@installation_type.installation_count} записях"
    else
      @installation_type.destroy
      redirect_to admin_installation_types_path(system: system),
                  notice: 'Тип места установки удалён'
    end
  end
  
  def reorder
    params[:installation_types].each_with_index do |id, index|
      InstallationType.find(id).update(position: index)
    end
    
    head :ok
  end
  
  private
  
  def set_installation_type
    @installation_type = InstallationType.find(params[:id])
  end
  
  def installation_type_params
    params.require(:installation_type).permit(:system, :name, :code, :active)
  end
end
```

#### 6. Views

```erb
<!-- app/views/admin/equipment_types/index.html.erb -->
<div class="container mx-auto py-8">
  <h1 class="text-3xl font-bold mb-6">Типы оборудования</h1>
  
  <!-- Вкладки системы -->
  <div class="flex gap-4 mb-6 border-b">
    <% ['cute', 'fids', 'zamar'].each do |system| %>
      <a href="<%= admin_equipment_types_path(system: system) %>"
         class="px-4 py-2 font-medium <%= 'text-blue-600 border-b-2 border-blue-600' if @system == system %>">
        <%= system.upcase %>
      </a>
    <% end %>
  </div>
  
  <div class="flex justify-end mb-6">
    <%= link_to "Добавить тип", new_admin_equipment_type_path, class: "px-4 py-2 bg-blue-600 text-white rounded" %>
  </div>
  
  <div class="bg-white rounded-lg shadow">
    <table class="w-full">
      <thead class="bg-gray-50 border-b">
        <tr>
          <th class="px-6 py-3 text-left text-sm font-medium">Название</th>
          <th class="px-6 py-3 text-left text-sm font-medium">Код</th>
          <th class="px-6 py-3 text-left text-sm font-medium">Активен</th>
          <th class="px-6 py-3 text-left text-sm font-medium">Используется</th>
          <th class="px-6 py-3 text-right text-sm font-medium">Действия</th>
        </tr>
      </thead>
      <tbody class="divide-y">
        <% @equipment_types.each do |type| %>
          <tr>
            <td class="px-6 py-4"><%= type.name %></td>
            <td class="px-6 py-4 text-sm text-gray-500"><%= type.code %></td>
            <td class="px-6 py-4">
              <span class="<%= type.active? ? 'text-green-600' : 'text-red-600' %>">
                <%= type.active? ? 'Да' : 'Нет' %>
              </span>
            </td>
            <td class="px-6 py-4 text-sm text-gray-500"><%= type.equipment_count %></td>
            <td class="px-6 py-4 text-right">
              <%= link_to "Редактировать", edit_admin_equipment_type_path(type), 
                  class: "text-blue-600 hover:underline mr-4" %>
              <% if type.equipment_count == 0 %>
                <%= link_to "Удалить", admin_equipment_type_path(type), 
                    method: :delete, data: { confirm: 'Вы уверены?' },
                    class: "text-red-600 hover:underline" %>
              <% end %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
</div>
```

#### 7. Маршруты

```ruby
# config/routes.rb
namespace :admin do
  resources :equipment_types do
    collection do
      post :reorder
    end
  end
  
  resources :installation_types do
    collection do
      post :reorder
    end
  end
end
```

#### 8. Seed data

```ruby
# db/seeds.rb или db/seeds/equipment_types.rb

cute_equipment_types = [
  { name: 'Сканер', code: 'scanner', position: 1 },
  { name: 'Принтер посадочных талонов', code: 'boarding_pass_printer', position: 2 },
  { name: 'С примечанием', code: 's_primechaniem', position: 16 }
]

cute_equipment_types.each do |attrs|
  EquipmentType.find_or_create_by!(attrs.merge(system: 'cute', active: true))
end
```

#### 9. Примечание по оптимизации

⚡ **Производительность:**
- Индексы на (system, code) и (system, name) для быстрого поиска
- Scope для фильтрации активных типов
- Eager loading при выводе списков
- Без CSS transitions/animations для быстрого отклика

**Git commit:**
```bash
feat: централизованное управление типами оборудования и мест установки
```

---

## ПРОМПТ #15: Обновление типов оборудования CUTE/FIDS/Zamar

### Требования

Обновить списки типов оборудования для всех трёх систем согласно новым требованиям.

### Реализация

#### Миграция обновления типов

```ruby
# db/migrate/[timestamp]_update_equipment_and_installation_types.rb
class UpdateEquipmentAndInstallationTypes < ActiveRecord::Migration[8.0]
  def up
    # CUTE: заменить "Прочее" на "С примечанием"
    cute_prochee = EquipmentType.find_by(system: 'cute', name: 'Прочее')
    cute_prochee&.update!(name: 'С примечанием', code: 's_primechaniem')

    # FIDS: обновить типы оборудования
    EquipmentType.where(system: 'fids').delete_all
    
    fids_equipment_types = [
      { name: 'Монитор', code: 'monitor', position: 1 },
      { name: 'Контроллер', code: 'controller', position: 2 },
      { name: 'LED панель', code: 'led_panel', position: 3 },
      { name: 'LED контроллер', code: 'led_controller', position: 4 },
      { name: 'Сервер', code: 'server', position: 5 },
      { name: 'С примечанием', code: 's_primechaniem', position: 6 }
    ]
    
    fids_equipment_types.each do |attrs|
      EquipmentType.create!(attrs.merge(system: 'fids', active: true))
    end

    # Zamar: обновить типы оборудования
    EquipmentType.where(system: 'zamar').delete_all
    
    zamar_equipment_types = [
      { name: 'Планшет', code: 'tablet', position: 1 },
      { name: 'Сканер', code: 'scanner', position: 2 },
      { name: 'Ворота', code: 'gates', position: 3 },
      { name: 'С примечанием', code: 's_primechaniem', position: 4 }
    ]
    
    zamar_equipment_types.each do |attrs|
      EquipmentType.create!(attrs.merge(system: 'zamar', active: true))
    end

    # FIDS: обновить типы мест установки
    InstallationType.where(system: 'fids').delete_all
    
    fids_installation_types = [
      { name: 'Стойка регистрации', code: 'check_in_desk', position: 1 },
      { name: 'Выход на посадку', code: 'boarding_gate', position: 2 },
      { name: 'Табло', code: 'display_board', position: 3 },
      { name: 'Кластер', code: 'cluster', position: 4 },
      { name: 'Зона выдачи багажа', code: 'baggage_claim', position: 5 },
      { name: 'Комплектовка', code: 'assembly', position: 6 },
      { name: 'Бизнес зал', code: 'business_lounge', position: 7 },
      { name: 'VIP', code: 'vip', position: 8 },
      { name: 'Транзит', code: 'transit', position: 9 },
      { name: 'Зона досмотра', code: 'security_zone', position: 10 },
      { name: 'Комната', code: 'room', position: 11 }
    ]
    
    fids_installation_types.each do |attrs|
      InstallationType.create!(attrs.merge(system: 'fids', active: true))
    end

    # Zamar: обновить типы мест установки
    InstallationType.where(system: 'zamar').delete_all
    
    zamar_installation_types = [
      { name: 'DSM', code: 'dsm', position: 1 },
      { name: 'DBA', code: 'dba', position: 2 },
      { name: 'SBDO', code: 'sbdo', position: 3 }
    ]
    
    zamar_installation_types.each do |attrs|
      InstallationType.create!(attrs.merge(system: 'zamar', active: true))
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

**Git commit:**
```bash
feat: обновлены типы оборудования и мест установки для всех систем
```

---

## ПРОМПТ #11: Модальные окна для добавления/редактирования мест установки

### Требования

Добавить модальные окна для добавления и редактирования мест установки.

### Реализация

#### Контроллер

```ruby
# app/controllers/cute_installations_controller.rb
class CuteInstallationsController < ApplicationController
  def new
    @installation = CuteInstallation.new
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "installation-modal",
          partial: "form",
          locals: { installation: @installation, system: 'cute' }
        )
      end
    end
  end
  
  def create
    @installation = CuteInstallation.new(installation_params)
    
    if @installation.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("installations-table", 
                                partial: "installation_row", 
                                locals: { installation: @installation }),
            turbo_stream.update("installation-modal", ""),
            turbo_stream.update("flash-messages", 
                                partial: "shared/flash", 
                                locals: { notice: "Место установки добавлено" })
          ]
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "installation-modal",
            partial: "form",
            locals: { installation: @installation, system: 'cute' }
          )
        end
      end
    end
  end
  
  def edit
    @installation = CuteInstallation.find(params[:id])
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "installation-modal",
          partial: "form",
          locals: { installation: @installation, system: 'cute' }
        )
      end
    end
  end
  
  def update
    @installation = CuteInstallation.find(params[:id])
    
    if @installation.update(installation_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("installation-row-#{@installation.id}", 
                                 partial: "installation_row", 
                                 locals: { installation: @installation }),
            turbo_stream.update("installation-modal", ""),
            turbo_stream.update("flash-messages", 
                                partial: "shared/flash", 
                                locals: { notice: "Место установки обновлено" })
          ]
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "installation-modal",
            partial: "form",
            locals: { installation: @installation, system: 'cute' }
          )
        end
      end
    end
  end
  
  private
  
  def installation_params
    params.require(:cute_installation).permit(:terminal, :installation_type_id, :name, :note, :status)
  end
end
```

#### Views

```erb
<!-- app/views/shared/_installation_modal.html.erb -->
<div id="installation-modal-wrapper" 
     class="hidden fixed inset-0 z-50 flex items-center justify-center bg-black/50" 
     data-controller="modal">
  
  <div class="bg-white rounded-lg shadow-lg max-w-2xl w-full mx-4">
    <div class="flex items-center justify-between p-6 border-b">
      <h2 id="modal-title" class="text-xl font-semibold">
        Добавить место установки
      </h2>
      <button type="button" 
              class="text-gray-400 hover:text-gray-600"
              data-action="click->modal#close"
              aria-label="Close">
        ✕
      </button>
    </div>
    
    <div class="p-6">
      <%= turbo_frame_tag "installation-modal", target: "_top" do %>
        <!-- Форма будет загружена сюда -->
      <% end %>
    </div>
  </div>
</div>

<!-- app/views/cute_installations/_form.html.erb -->
<%= form_with model: installation, 
             url: installation.persisted? ? cute_installation_path(installation) : cute_installations_path,
             method: installation.persisted? ? :patch : :post,
             data: { turbo_frame: "installation-modal" },
             local: true do |form| %>
  
  <% if installation.errors.any? %>
    <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded mb-4">
      <ul>
        <% installation.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="space-y-4">
    <div>
      <%= form.label :terminal, "Терминал" %>
      <%= form.text_field :terminal, class: "w-full px-3 py-2 border rounded" %>
    </div>

    <div>
      <%= form.label :installation_type_id, "Тип места установки" %>
      <%= form.collection_select :installation_type_id,
          InstallationType.where(system: 'cute', active: true).order(:position),
          :id, :name,
          { prompt: 'Выберите тип' },
          { class: 'w-full px-3 py-2 border rounded' } %>
    </div>

    <div>
      <%= form.label :name, "Название места" %>
      <%= form.text_field :name, class: "w-full px-3 py-2 border rounded" %>
    </div>

    <div>
      <%= form.label :note, "Примечание" %>
      <%= form.text_area :note, rows: 3, class: "w-full px-3 py-2 border rounded" %>
    </div>

    <div>
      <%= form.label :status, "Статус" %>
      <%= form.select :status, 
          [['В работе', 'active'], ['Не используется', 'inactive']],
          {},
          { class: 'w-full px-3 py-2 border rounded' } %>
    </div>
  </div>

  <div class="flex justify-end gap-3 mt-6">
    <%= link_to "Отменить", "#", 
        class: "px-4 py-2 bg-gray-200 text-gray-800 rounded", 
        data: { action: "click->modal#close" } %>
    <%= form.submit installation.persisted? ? "Сохранить" : "Добавить", 
        class: "px-4 py-2 bg-blue-600 text-white rounded" %>
  </div>
<% end %>

<!-- app/views/cute_installations/_installation_row.html.erb -->
<tr id="installation-row-<%= installation.id %>">
  <td class="px-6 py-4"><%= installation.terminal %></td>
  <td class="px-6 py-4"><%= installation.installation_type&.name || "—" %></td>
  <td class="px-6 py-4"><%= installation.name %></td>
  <td class="px-6 py-4 text-sm"><%= installation.status %></td>
  <td class="px-6 py-4 text-right">
    <%= link_to "Изменить", 
        edit_cute_installation_path(installation, format: :turbo_stream), 
        data: { turbo_frame: "installation-modal", action: "click->modal#open" },
        class: "text-blue-600 hover:underline mr-2" %>
    <%= link_to "Просмотр", cute_installation_path(installation), 
        class: "text-gray-600 hover:underline" %>
  </td>
</tr>
```

#### Stimulus контроллер

```javascript
// app/javascript/controllers/modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open(event) {
    event.preventDefault()
    this.element.classList.remove('hidden')
  }

  close(event) {
    event.preventDefault()
    this.element.classList.add('hidden')
  }
}
```

**Git commit:**
```bash
feat: модальные окна для добавления и редактирования мест установки
```

---

## ПРОМПТ #10: История установки оборудования в карточке места установки

### Требования

Добавить блок "История установки оборудования" в карточку места установки.

### Реализация

#### Контроллер

```ruby
# app/controllers/cute_installations_controller.rb
def show
  @installation = CuteInstallation.find(params[:id])
  @installation_history = @installation.audit_logs
                                       .where("action ILIKE ?", "%установ%")
                                       .or(AuditLog.where(auditable: @installation)
                                                   .where("action ILIKE ?", "%снят%"))
                                       .order(created_at: :desc)
                                       .page(params[:page])
                                       .per(20)
end
```

#### Метод в модели

```ruby
# app/models/cute_installation.rb
def audit_logs
  AuditLog.where(auditable_type: 'CuteInstallation', auditable_id: id)
end

def installation_history
  audit_logs.where("action ILIKE ?", "%установ%")
            .or(audit_logs.where("action ILIKE ?", "%снят%"))
            .order(created_at: :desc)
end
```

#### View

```erb
<!-- app/views/cute_installations/show.html.erb -->
<div class="mt-6 bg-white rounded-lg shadow">
  <div class="px-6 py-4 border-b">
    <h3 class="text-lg font-semibold">История установки оборудования</h3>
  </div>
  
  <div class="p-6">
    <% if @installation_history.any? %>
      <table class="w-full text-sm">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-4 py-2 text-left">Дата и время</th>
            <th class="px-4 py-2 text-left">Тип</th>
            <th class="px-4 py-2 text-left">Модель</th>
            <th class="px-4 py-2 text-left">Инв. номер</th>
            <th class="px-4 py-2 text-left">Действие</th>
            <th class="px-4 py-2 text-left">Пользователь</th>
          </tr>
        </thead>
        <tbody class="divide-y">
          <% @installation_history.each do |log| %>
            <tr>
              <td class="px-4 py-2"><%= log.created_at.strftime("%d.%m.%Y %H:%M") %></td>
              <td class="px-4 py-2"><%= log.equipment_type_from_changes %></td>
              <td class="px-4 py-2"><%= log.model_from_changes %></td>
              <td class="px-4 py-2"><%= log.inventory_number_from_changes %></td>
              <td class="px-4 py-2">
                <span class="px-2 py-1 rounded text-xs font-medium
                  <%= case log.action_status
                      when 'success' then 'bg-green-100 text-green-800'
                      when 'warning' then 'bg-yellow-100 text-yellow-800'
                      else 'bg-gray-100 text-gray-800'
                      end %>">
                  <%= log.action_display %>
                </span>
              </td>
              <td class="px-4 py-2"><%= log.user&.full_name || "Система" %></td>
            </tr>
          <% end %>
        </tbody>
      </table>
      
      <div class="mt-4">
        <%= paginate @installation_history %>
      </div>
    <% else %>
      <p class="text-gray-500">История установки оборудования пока пуста</p>
    <% end %>
  </div>
</div>
```

#### Helper методы в AuditLog

```ruby
# app/models/audit_log.rb
def equipment_type_from_changes
  parsed = JSON.parse(changes) rescue {}
  parsed.dig('equipment_type', 1) || parsed.dig('equipment_type', 0) || "—"
end

def model_from_changes
  parsed = JSON.parse(changes) rescue {}
  parsed.dig('model', 1) || parsed.dig('model', 0) || "—"
end

def inventory_number_from_changes
  parsed = JSON.parse(changes) rescue {}
  parsed.dig('inventory_number', 1) || parsed.dig('inventory_number', 0) || "—"
end

def action_display
  case action
  when /установ/i
    "Установлено"
  when /снят/i
    "Снято"
  when /замен/i
    "Заменено"
  else
    action
  end
end

def action_status
  case action
  when /установ/i
    "success"
  when /снят/i
    "warning"
  when /замен/i
    "info"
  else
    "default"
  end
end
```

**Git commit:**
```bash
feat: история установки оборудования в карточке места установки
```

---

## ПРОМПТ #12: Импорт оборудования из Excel/CSV файлов

### Требования

Реализовать функцию импорта оборудования из Excel/CSV файлов для администратора с оптимизацией производительности (batch inserts).

### Реализация

#### Service объект

```ruby
# app/services/equipment_import_service.rb
require 'csv'
require 'roo'

class EquipmentImportService
  def initialize(file, system)
    @file = file
    @system = system
    @imported = 0
    @skipped = 0
    @errors = []
  end

  def import
    case @file.content_type
    when 'text/csv'
      import_from_csv
    when 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      import_from_xlsx
    else
      return { success: false, error: "Неподдерживаемый формат файла" }
    end

    { success: true, imported: @imported, skipped: @skipped, errors: @errors }
  rescue => e
    { success: false, error: e.message }
  end

  private

  def import_from_csv
    rows = []
    
    CSV.foreach(@file.path, headers: true, col_sep: ';') do |row|
      rows << row.to_h
    end
    
    process_rows(rows)
  end

  def import_from_xlsx
    xlsx = Roo::Spreadsheet.open(@file.path)
    headers = xlsx.row(1)
    rows = []
    
    (2..xlsx.last_row).each do |i|
      rows << Hash[headers.zip(xlsx.row(i))]
    end
    
    process_rows(rows)
  end

  def process_rows(rows)
    equipment_attrs = []
    
    rows.each do |row|
      equipment_type_name = row['Тип оборудования']&.strip
      model = row['Модель']&.strip
      inventory_number = row['Инвентарный номер']&.strip
      serial_number = row['Серийный номер']&.strip
      terminal = row['Терминал']&.strip
      installation_type_name = row['Тип места установки']&.strip
      installation_name = row['Название места']&.strip
      status = row['Статус']&.strip
      note = row['Примечание']&.strip

      if model.blank? || inventory_number.blank?
        @skipped += 1
        @errors << "Строка пропущена: отсутствует модель или инвентарный номер"
        next
      end

      equipment_type = find_or_create_equipment_type(equipment_type_name)
      installation_type = find_or_create_installation_type(installation_type_name) if installation_type_name.present?
      installation = find_or_create_installation(terminal, installation_type, installation_name) if terminal.present?

      equipment_attrs << {
        equipment_type_id: equipment_type&.id,
        model: model,
        inventory_number: inventory_number,
        serial_number: serial_number,
        status: map_status(status),
        note: note,
        installation_id: installation&.id,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    # Batch insert для лучшей производительности
    insert_equipment_batch(equipment_attrs) if equipment_attrs.any?
  end

  def insert_equipment_batch(attrs)
    equipment_class = equipment_class_for_system
    
    equipment_class.insert_all(attrs) do |_result|
      @imported += 1
    end
  end

  def find_or_create_equipment_type(name)
    return nil if name.blank?
    
    EquipmentType.find_or_create_by!(system: @system, name: name) do |et|
      et.code = name.parameterize.underscore
      et.position = EquipmentType.where(system: @system).maximum(:position).to_i + 1
    end
  end

  def find_or_create_installation_type(name)
    return nil if name.blank?
    
    InstallationType.find_or_create_by!(system: @system, name: name) do |it|
      it.code = name.parameterize.underscore
      it.position = InstallationType.where(system: @system).maximum(:position).to_i + 1
    end
  end

  def find_or_create_installation(terminal, installation_type, name)
    installation_class = installation_class_for_system
    
    installation_class.find_or_create_by!(
      terminal: terminal,
      installation_type: installation_type,
      name: name
    ) { |inst| inst.status = 'active' }
  end

  def equipment_class_for_system
    case @system
    when 'cute' then CuteEquipment
    when 'fids' then FidsEquipment
    when 'zamar' then ZamarEquipment
    end
  end

  def installation_class_for_system
    case @system
    when 'cute' then CuteInstallation
    when 'fids' then FidsInstallation
    when 'zamar' then ZamarInstallation
    end
  end

  def map_status(status_text)
    case status_text&.downcase
    when 'в работе', 'активное', 'active'
      'active'
    when 'на складе', 'склад', 'storage'
      'storage'
    when 'в ремонте', 'ремонт', 'repair'
      'repair'
    else
      'active'
    end
  end
end
```

#### Контроллер

```ruby
# app/controllers/admin/imports_controller.rb
class Admin::ImportsController < ApplicationController
  before_action :authenticate_admin!

  def new
    @systems = [['CUTE', 'cute'], ['FIDS', 'fids'], ['ZAMAR', 'zamar']]
  end

  def create
    file = params[:import_file]
    system = params[:system]
    
    if file.blank?
      redirect_to admin_import_path, alert: "Выберите файл для импорта"
      return
    end

    result = EquipmentImportService.new(file, system).import
    
    if result[:success]
      AuditLog.create!(
        user: current_user,
        action: "Импортировано #{result[:imported]} записей оборудования (#{system.upcase})",
        auditable_type: 'Import',
        auditable_id: nil
      )
      
      redirect_to admin_import_path, 
                  notice: "Импортировано: #{result[:imported]}, Пропущено: #{result[:skipped]}"
    else
      redirect_to admin_import_path, alert: "Ошибка импорта: #{result[:error]}"
    end
  end

  def template
    respond_to do |format|
      format.csv do
        send_data generate_csv_template, 
                  filename: "equipment_import_template.csv",
                  type: 'text/csv; charset=utf-8'
      end
    end
  end

  private

  def generate_csv_template
    CSV.generate(col_sep: ';', encoding: 'UTF-8') do |csv|
      csv << ['Тип оборудования', 'Модель', 'Инвентарный номер', 'Серийный номер', 
              'Терминал', 'Тип места установки', 'Название места', 'Статус', 'Примечание']
      csv << ['Сканер', 'HP ScanJet Pro 3500', 'INV-001', 'SN12345678', 
              'A', 'Стойка регистрации', 'Стойка 1', 'В работе', 'Установлен 01.02.2026']
    end
  end
end
```

#### View

```erb
<!-- app/views/admin/imports/new.html.erb -->
<div class="container mx-auto py-8 max-w-4xl">
  <h1 class="text-3xl font-bold mb-6">Импорт оборудования</h1>

  <%= form_with url: admin_import_path, multipart: true, local: true do |form| %>
    
    <div class="bg-white rounded-lg shadow p-6 mb-6">
      <div class="mb-4">
        <%= form.label :system, "Система" %>
        <%= form.select :system, 
            [['CUTE', 'cute'], ['FIDS', 'fids'], ['ZAMAR', 'zamar']],
            {},
            { class: 'w-full px-3 py-2 border rounded' } %>
      </div>

      <div class="mb-4">
        <%= form.label :import_file, "Файл для импорта (CSV или XLSX)" %>
        <%= form.file_field :import_file, 
            accept: ".csv,.xlsx",
            class: "w-full px-3 py-2 border rounded" %>
        <p class="text-sm text-gray-500 mt-2">
          Поддерживаемые форматы: CSV (с разделителем ;), Excel (.xlsx)
        </p>
      </div>

      <div class="flex justify-end gap-3">
        <%= link_to "Отменить", admin_path, class: "px-4 py-2 bg-gray-200 rounded" %>
        <%= form.submit "Импортировать", class: "px-4 py-2 bg-blue-600 text-white rounded" %>
      </div>
    </div>
  <% end %>

  <div class="bg-white rounded-lg shadow p-6">
    <h2 class="text-xl font-semibold mb-4">Пример структуры файла</h2>
    
    <table class="w-full text-sm border-collapse">
      <thead class="bg-gray-50">
        <tr>
          <th class="border px-3 py-2 text-left">Тип оборудования</th>
          <th class="border px-3 py-2 text-left">Модель</th>
          <th class="border px-3 py-2 text-left">Инвентарный номер</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td class="border px-3 py-2">Сканер</td>
          <td class="border px-3 py-2">HP ScanJet Pro 3500</td>
          <td class="border px-3 py-2">INV-001</td>
        </tr>
      </tbody>
    </table>
    
    <%= link_to "Скачать шаблон", admin_import_template_path(format: :csv), 
        class: "mt-4 inline-block px-4 py-2 bg-gray-200 rounded" %>
  </div>
</div>
```

**Git commit:**
```bash
feat: импорт оборудования из Excel и CSV файлов с оптимизацией (batch inserts)
```

---

## ПРОМПТ #13: Улучшение отображения audit_logs

### Требования

Улучшить отображение истории изменений с использованием человекопонятного языка.

### Реализация

#### Модель

```ruby
# app/models/audit_log.rb
class AuditLog < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :auditable, polymorphic: true, optional: true

  def changes_display_html
    return action if changes.blank?
    
    parsed_changes = JSON.parse(changes) rescue {}
    return action if parsed_changes.empty?
    
    results = []
    
    parsed_changes.each do |field, values|
      old_value = values[0]
      new_value = values[1]
      
      field_name = field_name_in_russian(field)
      old_display = format_value(field, old_value)
      new_display = format_value(field, new_value)
      
      results << "<strong>#{field_name}:</strong> <span class='line-through text-red-600'>#{old_display}</span> → <span class='text-green-600'>#{new_display}</span>"
    end
    
    results.join('<br>').html_safe
  end

  def auditable_display
    return "Удалён" unless auditable
    
    case auditable_type
    when 'CuteEquipment', 'FidsEquipment', 'ZamarEquipment'
      "#{auditable.model} (#{auditable.inventory_number})"
    when 'CuteInstallation', 'FidsInstallation', 'ZamarInstallation'
      "#{auditable.terminal} - #{auditable.name}"
    else
      "#{auditable_type} ##{auditable_id}"
    end
  end

  private

  def field_name_in_russian(field)
    mapping = {
      'terminal' => 'Терминал',
      'equipment_type' => 'Тип оборудования',
      'equipment_type_id' => 'Тип оборудования',
      'model' => 'Модель',
      'inventory_number' => 'Инвентарный номер',
      'serial_number' => 'Серийный номер',
      'status' => 'Статус',
      'installation_id' => 'Место установки',
      'name' => 'Название'
    }
    
    mapping[field] || field.humanize
  end

  def format_value(field, value)
    return '(пусто)' if value.blank?
    
    case field
    when 'status'
      status_in_russian(value)
    else
      value.to_s
    end
  end

  def status_in_russian(status)
    { 'active' => 'В работе', 'storage' => 'На складе', 'repair' => 'В ремонте' }[status] || status
  end
end
```

#### Контроллер

```ruby
# app/controllers/audit_logs_controller.rb
class AuditLogsController < ApplicationController
  before_action :authenticate_user!

  def index
    @audit_logs = AuditLog.includes(:user, :auditable)
                          .order(created_at: :desc)
                          .page(params[:page])
                          .per(50)
  end
end
```

#### View

```erb
<!-- app/views/audit_logs/index.html.erb -->
<div class="container mx-auto py-8">
  <h1 class="text-3xl font-bold mb-6">История изменений</h1>

  <div class="bg-white rounded-lg shadow overflow-hidden">
    <table class="w-full">
      <thead class="bg-gray-50 border-b">
        <tr>
          <th class="px-6 py-3 text-left text-sm font-medium">Дата</th>
          <th class="px-6 py-3 text-left text-sm font-medium">Пользователь</th>
          <th class="px-6 py-3 text-left text-sm font-medium">Действие</th>
          <th class="px-6 py-3 text-left text-sm font-medium">Изменения</th>
          <th class="px-6 py-3 text-left text-sm font-medium">Объект</th>
        </tr>
      </thead>
      <tbody class="divide-y">
        <% @audit_logs.each do |log| %>
          <tr>
            <td class="px-6 py-4 text-sm"><%= log.created_at.strftime("%d.%m.%Y %H:%M") %></td>
            <td class="px-6 py-4 text-sm"><%= log.user&.full_name || "Система" %></td>
            <td class="px-6 py-4 text-sm"><%= log.action %></td>
            <td class="px-6 py-4 text-sm"><%= log.changes_display_html %></td>
            <td class="px-6 py-4 text-sm">
              <% if log.auditable %>
                <%= link_to log.auditable_display, 
                    polymorphic_path(log.auditable),
                    class: "text-blue-600 hover:underline" %>
              <% else %>
                <%= log.auditable_display %>
              <% end %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>

    <div class="px-6 py-4 bg-gray-50 border-t">
      <%= paginate @audit_logs %>
    </div>
  </div>
</div>
```

**Git commit:**
```bash
feat: человекопонятное отображение истории изменений
```

---

## ПРОМПТ #14: Пагинация для больших списков + тестовые данные

### Требования

Оптимизировать отображение больших списков с пагинацией и создать тестовые данные.

### Реализация

#### Контроллеры

```ruby
# app/controllers/cute_equipments_controller.rb
class CuteEquipmentsController < ApplicationController
  def index
    @per_page = params[:per_page]&.to_i || 20
    @per_page = 20 unless [20, 50, 100].include?(@per_page)
    
    @equipments = CuteEquipment.includes(:equipment_type, :installation)
                               .page(params[:page])
                               .per(@per_page)
  end
end
```

#### Gem добавления

```ruby
# Gemfile
gem 'pagy', '~> 6.0'        # Лёгкая пагинация, быстрая
gem 'roo', '~> 2.10'        # Чтение Excel
gem 'write_xlsx', '~> 1.11' # Запись Excel
```

#### Rake task для тестовых данных

```ruby
# lib/tasks/test_data.rake
namespace :test_data do
  desc "Создать 200 тестовых записей оборудования"
  task create_equipments: :environment do
    puts "Создание тестовых данных..."
    
    equipment_types = EquipmentType.where(system: 'cute', active: true)
    installations = CuteInstallation.where(status: 'active')
    
    attrs = []
    200.times do |i|
      attrs << {
        equipment_type_id: equipment_types.sample&.id,
        model: "Test Model #{i + 1}",
        inventory_number: "TEST-#{sprintf('%04d', i + 1)}",
        serial_number: "SN#{rand(10000000..99999999)}",
        status: ['active', 'storage'].sample,
        installation_id: [nil, installations.sample&.id].sample,
        created_at: Time.current,
        updated_at: Time.current
      }
    end
    
    CuteEquipment.insert_all(attrs)
    puts "✓ Создано 200 записей для CUTE"
  end
end
```

#### View с пагинацией

```erb
<!-- app/views/cute_equipments/index.html.erb -->
<div class="flex justify-between items-center mb-6">
  <h1 class="text-3xl font-bold">Оборудование CUTE</h1>
  
  <div class="flex gap-4 items-center">
    <%= form_with url: cute_equipments_path, method: :get, local: true do |f| %>
      <label class="text-sm">Показать:</label>
      <%= f.select :per_page, [[20, 20], [50, 50], [100, 100]], 
          { selected: @per_page },
          { class: 'px-3 py-2 border rounded', onchange: 'this.form.submit()' } %>
      <span class="text-sm text-gray-500">записей</span>
    <% end %>
  </div>
</div>

<div class="bg-white rounded-lg shadow">
  <div class="px-6 py-4 border-b text-sm text-gray-600">
    Показано <%= (@equipments.current_page - 1) * @per_page + 1 %> - 
    <%= [(@equipments.current_page - 1) * @per_page + @equipments.size, @equipments.total_count].min %>
    из <%= @equipments.total_count %> записей
  </div>

  <table class="w-full">
    <thead class="bg-gray-50 border-b">
      <tr>
        <th class="px-6 py-3 text-left">Модель</th>
        <th class="px-6 py-3 text-left">Инвентарный номер</th>
        <th class="px-6 py-3 text-left">Тип</th>
        <th class="px-6 py-3 text-left">Статус</th>
      </tr>
    </thead>
    <tbody class="divide-y">
      <% @equipments.each do |eq| %>
        <tr>
          <td class="px-6 py-4"><%= eq.model %></td>
          <td class="px-6 py-4"><%= eq.inventory_number %></td>
          <td class="px-6 py-4"><%= eq.equipment_type&.name || "—" %></td>
          <td class="px-6 py-4"><%= eq.status %></td>
        </tr>
      <% end %>
    </tbody>
  </table>

  <div class="px-6 py-4 bg-gray-50 border-t">
    <%== pagy_nav(@pagy) %>
  </div>
</div>
```

**Git commit:**
```bash
feat: пагинация с оптимизацией и тестовые данные (batch inserts)
```

---

## ⚡ ОПТИМИЗАЦИЯ ПРОИЗВОДИТЕЛЬНОСТИ

### Применено во всех промптах:

1. **Без CSS анимаций** — только использование `hidden`/`visible` классов
2. **Database индексы** — на часто используемые поля
3. **Eager loading** — `.includes()` для предотвращения N+1 проблем
4. **Batch inserts** — `insert_all()` для массового импорта
5. **Паги вместо Kaminari** — более лёгкая библиотека пагинации
6. **Кэширование счётчиков** — для быстрого отклика
7. **Scope для фильтрации** — активные типы по умолчанию

### Gems для Gemfile

```ruby
gem 'pagy', '~> 6.0'         # Пагинация
gem 'roo', '~> 2.10'         # Чтение Excel
gem 'write_xlsx', '~> 1.11'  # Запись Excel
```

---

## 📋 ИТОГОВАЯ ПОСЛЕДОВАТЕЛЬНОСТЬ

1. **ПРОМПТ #9** → Модели EquipmentType, InstallationType, контроллеры, views
2. **ПРОМПТ #15** → Миграция обновления типов
3. **ПРОМПТ #11** → Модальные окна (Turbo Streams, Stimulus)
4. **ПРОМПТ #10** → История в карточке места
5. **ПРОМПТ #12** → Импорт с batch inserts
6. **ПРОМПТ #13** → Красивая история изменений
7. **ПРОМПТ #14** → Пагинация + тестовые данные

---

## ✅ CHECKLIST

- [ ] Создать модели EquipmentType и InstallationType
- [ ] Выполнить миграции
- [ ] Обновить существующие модели (belongs_to)
- [ ] Создать админ-контроллеры и views
- [ ] Проверить маршруты
- [ ] Запустить seed данные
- [ ] Тестирование импорта Excel/CSV
- [ ] Проверка производительности (N+1, запросы БД)
- [ ] Git commits по каждому шагу

---

**Статус:** ✅ Версия 7.0 готова  
**Оптимизация:** ⚡ Производительность  
**Rails:** 8.0.4 + Turbo + Stimulus  
**Дата:** 2 февраля 2026
