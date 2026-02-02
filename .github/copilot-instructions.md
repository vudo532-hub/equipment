# Equipment Management System - AI Coding Instructions

## Project Overview
Rails 8.0.4 application for managing airport equipment across three subsystems: **CUTE** (registration), **FIDS** (information displays), **ZAMAR** (baggage system). Each subsystem has its own equipment and installation models with identical structure.

## Architecture Pattern
The codebase follows a **parallel module pattern** - three identical subsystems with prefixed models/controllers:
- `CuteEquipment`, `CuteInstallation`, `CuteEquipmentsController`
- `FidsEquipment`, `FidsInstallation`, `FidsEquipmentsController`  
- `ZamarEquipment`, `ZamarInstallation`, `ZamarEquipmentsController`

**⚠️ IMPORTANT: When modifying one subsystem, apply the same changes to all three.**

## Key Technologies
- **Frontend**: Tailwind CSS, Turbo/Stimulus (Hotwire), no React/Vue
- **Search**: Ransack gem for filtering (`@q = Model.ransack(params[:q])`)
- **Audit**: `audited` gem - all equipment changes are tracked
- **Auth**: Devise + roles (`admin`, `editor`, `viewer` in User model)
- **Excel export**: `write_xlsx` gem via `app/views/exports/*.xlsx.axlsx`
- **Pagination**: Pagy gem

## Critical Patterns

### Equipment-Installation Relationship
```ruby
# Equipment belongs_to installation (optional)
belongs_to :cute_installation, optional: true

# Installations have many equipments
has_many :cute_equipments, dependent: :nullify
```

### Attach/Detach Equipment via AJAX
Installations have `search_equipment`, `attach_equipment`, `detach_equipment` member routes. These use JSON responses with `location.reload()` on success.

### Modal Forms (Simple Pattern)
Equipment add/edit uses shared modal system - **simple onclick approach, no complex animations**:
- `app/views/shared/_equipment_modal.html.erb` - modal container with `bg-opacity-50`
- `app/views/shared/_equipment_modal_form.html.erb` - form content in turbo-frame
- Modal opens via `openEquipmentModal()`, closes via `closeEquipmentModal()`
- After successful save: modal closes, page refreshes

### Status & Type Enums
All equipment models share these enums (defined in each model):
- `status`: active, maintenance, waiting_repair, ready_to_dispatch, decommissioned, transferred, with_note
- `equipment_type`: varies by subsystem (see model files)

### Russian Localization
All UI text is in Russian. Helper methods provide translations:
- `equipment.status_text`, `equipment.equipment_type_text`
- `equipment.human_status`, `equipment.human_equipment_type`

## Repair System (Ремонт)

### Data Flow
1. Equipment with `status: :maintenance` appears in repair list (`/repairs`)
2. User selects equipment and creates batch → `RepairBatch` + `RepairBatchItem` records
3. Equipment is automatically detached from installation when sent to repair
4. Batch generates unique number: `REP-{YEAR}-{NUMBER}` (e.g., REP-2026-001)

### Key Models
- `RepairBatch` - акт ремонта (repair act), has many items
- `RepairBatchItem` - stores equipment snapshot (system, serial, model, terminal, installation)

### Repair Acts (`/repairs/acts`)
- View created repair batches
- Export to Excel via `repairs/acts#export_to_excel`
- Statuses: sent → in_progress → received → closed

## Excel Export Structure

### Export Files Location
`app/views/exports/` - uses `.xlsx.axlsx` extension

### Export Pattern (example: cute_equipments.xlsx.axlsx)
```ruby
wb = xlsx_package.workbook
wb.add_worksheet(name: "Оборудование CUTE") do |sheet|
  # Header style with blue background
  header_style = sheet.styles.add_style(bg_color: "4472C4", fg_color: "FFFFFF", b: true)
  
  # Add header row
  sheet.add_row ["№", "Название", "Тип", ...], style: header_style
  
  # Add data rows
  @equipments.each_with_index do |equipment, index|
    sheet.add_row [index + 1, equipment.equipment_type_text, ...]
  end
  
  # Set column widths
  sheet.column_widths 5, 25, 20, ...
end
```

### Export Routes
- `/export/cute_equipments.xlsx`, `/export/fids_equipments.xlsx`, `/export/zamar_equipments.xlsx`
- `/export/cute_installations.xlsx`, `/export/fids_installations.xlsx`, `/export/zamar_installations.xlsx`
- `/repairs/acts/:id/export_to_excel` - repair act export

## CUTE Installation Types (Hardcoded)
Update in ALL these locations when changing:
- `app/views/cute_installations/_form.html.erb`
- `app/views/cute_installations/index.html.erb` (filters)
- `app/views/cute_equipments/index.html.erb` (filters)
- `db/seeds.rb`

Current types: Стойка регистрации, Выход на посадку, Транзит, Негабарит, VIP, Комплектовка, Камера хранения, Учебный класс, Склад, ЦУИТ, Комната, Киоск самообслуживания

## Developer Commands
```bash
bin/dev           # Start dev server (Rails + Tailwind watcher)
rails db:seed     # Populate test data (idempotent)
rails spec        # Run RSpec tests
```

## File Locations
- **Models**: `app/models/{cute,fids,zamar}_{equipment,installation}.rb`
- **Controllers**: `app/controllers/{cute,fids,zamar}_{equipments,installations}_controller.rb`
- **Views**: `app/views/{cute,fids,zamar}_{equipments,installations}/`
- **Shared partials**: `app/views/shared/`
- **Exports**: `app/views/exports/`
- **Repairs**: `app/controllers/repairs_controller.rb`, `app/controllers/repairs/acts_controller.rb`
- **Routes**: `config/routes.rb`
- **Documentation**: `.md/` folder contains implementation summaries

## Common Gotchas
1. **Admin bypass**: Admins can attach multiple equipment of same type to one installation; regular users cannot (see `current_user_admin` virtual attribute)
2. **Deletion permissions**: `can_delete?` helper checks if user has admin role
3. **Modal pattern**: Use simple `onclick="openEquipmentModal()"`, NOT complex Stimulus controllers
4. **Repair detachment**: Equipment is automatically unassigned from installation when sent to repair
5. **API development paused**: `/api/v1/*` routes exist but API development is on hold

## Adding New Features Checklist
- [ ] Apply changes to all 3 subsystems (CUTE, FIDS, ZAMAR)
- [ ] Update Russian translations if adding UI text
- [ ] Update filters if adding new filterable fields
- [ ] Update exports if adding new data columns
- [ ] Test modal functionality if touching equipment forms
