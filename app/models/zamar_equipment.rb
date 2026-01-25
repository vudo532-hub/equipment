class ZamarEquipment < ApplicationRecord
  # Audited
  audited

  # Associations
  belongs_to :user, optional: true
  belongs_to :zamar_installation, optional: true
  belongs_to :last_changed_by, class_name: "User", optional: true

  # Enums
  enum :equipment_type, {
    dsm: 0,
    dba: 1,
    sbdo: 2,
    gates: 3,
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

  # Scopes
  scope :ordered, -> { order(last_action_date: :desc, created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_type, ->(type) { where(equipment_type: type) if type.present? }
  scope :by_installation, ->(installation_id) { where(zamar_installation_id: installation_id) if installation_id.present? }
  scope :not_decommissioned, -> { where.not(status: :decommissioned) }
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
    return "—" if equipment_type.blank?
    I18n.t("zamar_equipment_types.#{equipment_type}", default: equipment_type.to_s.upcase)
  end

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

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[equipment_type equipment_model inventory_number serial_number status note created_at updated_at last_action_date zamar_installation_id]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[zamar_installation last_changed_by]
  end

  # Терминал через место установки
  def terminal
    zamar_installation&.terminal
  end

  def terminal_name
    zamar_installation&.terminal_name
  end

  private

  def update_last_action_date
    self.last_action_date = Time.current if changed?
  end
end
