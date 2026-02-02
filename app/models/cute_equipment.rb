class CuteEquipment < ApplicationRecord
  # Audited
  audited

  # Associations
  belongs_to :user, optional: true
  belongs_to :cute_installation, optional: true
  belongs_to :last_changed_by, class_name: "User", optional: true
  belongs_to :equipment_type_ref, class_name: "EquipmentType", optional: true

  # Virtual attribute for validation context
  attr_accessor :current_user_admin

  # Enums
  enum :equipment_type, {
    boarding_pass_printer: 0,
    baggage_tag_printer: 1,
    keyboard: 2,
    scanner: 3,
    gate_reader: 4,
    flight_document_printer: 5,
    monitor: 6,
    computer: 7,
    other: 99
  }

  enum :status, {
    active: 0,
    maintenance: 1,
    waiting_repair: 2,
    ready_to_dispatch: 3,
    decommissioned: 4,
    transferred: 5,
    with_note: 6
  }, default: :active

  # Validations
  validates :equipment_type, presence: true
  validates :equipment_model, length: { maximum: 255 }
  validates :inventory_number, presence: true,
                               length: { maximum: 100 },
                               uniqueness: { message: "уже существует" }
  validates :serial_number, presence: true,
                            length: { maximum: 100 },
                            uniqueness: { message: "уже существует" }
  validates :note, length: { maximum: 2000 }
  validate :unique_equipment_type_per_installation, unless: :current_user_admin

  # Scopes
  scope :ordered, -> { order(last_action_date: :desc, created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_type, ->(type) { where(equipment_type: type) if type.present? }
  scope :by_installation, ->(installation_id) { where(cute_installation_id: installation_id) if installation_id.present? }
  scope :not_decommissioned, -> { where.not(status: :decommissioned) }
  scope :unassigned, -> { where(cute_installation_id: nil) }
  scope :search, ->(query) {
    return all if query.blank?
    where("equipment_model ILIKE :q OR inventory_number ILIKE :q OR serial_number ILIKE :q", q: "%#{query}%")
  }

  # Callbacks
  before_save :update_last_action_date
  strip_attributes
  nilify_blanks

  def to_s
    "#{equipment_type_text} - #{inventory_number}"
  end

  def equipment_type_text
    # Сначала проверяем новую связь с EquipmentType
    return equipment_type_ref.name if equipment_type_ref.present?
    # Иначе используем старый enum
    return "—" if equipment_type.blank?
    I18n.t("cute_equipment_types.#{equipment_type}", default: equipment_type.to_s.humanize)
  end

  # Название типа оборудования для новой системы
  def equipment_type_name
    equipment_type_ref&.name || equipment_type_text
  end

  # Алиас для API
  alias_method :human_equipment_type, :equipment_type_text

  def status_color
    case status
    when "active" then "bg-green-100 text-green-800"
    when "maintenance" then "bg-yellow-100 text-yellow-800"
    when "waiting_repair" then "bg-orange-100 text-orange-800"
    when "ready_to_dispatch" then "bg-blue-100 text-blue-800"
    when "decommissioned" then "bg-red-100 text-red-800"
    when "transferred" then "bg-purple-100 text-purple-800"
    when "with_note" then "bg-gray-100 text-gray-800"
    else "bg-gray-100 text-gray-800"
    end
  end

  def status_text
    return "—" if status.blank?
    I18n.t("equipment_statuses.#{status}", default: status.to_s.humanize)
  end

  # Алиас для API
  alias_method :human_status, :status_text

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[equipment_type equipment_model inventory_number serial_number status note created_at updated_at last_action_date cute_installation_id]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[cute_installation last_changed_by]
  end

  # Терминал через место установки
  def terminal
    cute_installation&.terminal
  end

  def terminal_name
    cute_installation&.terminal_name
  end

  # Поиск дублирующего оборудования того же типа на месте установки
  def self.find_duplicate(equipment_type, installation_id, exclude_id = nil)
    return nil if installation_id.blank?
    
    scope = where(equipment_type: equipment_type, cute_installation_id: installation_id)
    scope = scope.where.not(id: exclude_id) if exclude_id.present?
    scope.first
  end

  private

  def update_last_action_date
    self.last_action_date = Time.current if changed?
  end

  def unique_equipment_type_per_installation
    return if cute_installation_id.blank?
    
    duplicate = self.class.find_duplicate(equipment_type, cute_installation_id, id)
    if duplicate.present?
      errors.add(:base, "Оборудование типа '#{equipment_type_text}' уже привязано к этому месту установки (инв. №#{duplicate.inventory_number})")
    end
  end
end
