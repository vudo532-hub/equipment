class CuteEquipment < ApplicationRecord
  # Audited
  audited associated_with: :user

  # Associations
  belongs_to :user
  belongs_to :cute_installation, optional: true

  # Enums
  enum :status, {
    active: 0,
    inactive: 1,
    maintenance: 2,
    archived: 3
  }, default: :active

  # Validations
  validates :equipment_type, presence: true, length: { maximum: 100 }
  validates :equipment_model, length: { maximum: 255 }
  validates :inventory_number, presence: true,
                               length: { maximum: 100 },
                               uniqueness: { scope: :user_id, message: "уже существует" }
  validates :serial_number, length: { maximum: 100 }
  validates :note, length: { maximum: 2000 }

  # Scopes
  scope :ordered, -> { order(last_action_date: :desc, created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_type, ->(type) { where(equipment_type: type) if type.present? }
  scope :by_installation, ->(installation_id) { where(cute_installation_id: installation_id) if installation_id.present? }
  scope :not_archived, -> { where.not(status: :archived) }
  scope :search, ->(query) {
    return all if query.blank?
    where("equipment_type ILIKE :q OR equipment_model ILIKE :q OR inventory_number ILIKE :q OR serial_number ILIKE :q", q: "%#{query}%")
  }

  # Callbacks
  before_save :update_last_action_date
  strip_attributes
  nilify_blanks

  def to_s
    "#{equipment_type} - #{inventory_number}"
  end

  def status_color
    case status
    when "active" then "green"
    when "inactive" then "gray"
    when "maintenance" then "yellow"
    when "archived" then "red"
    else "gray"
    end
  end

  def status_text
    I18n.t("equipment_statuses.#{status}", default: status.humanize)
  end

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[name equipment_type equipment_model inventory_number serial_number status notes created_at updated_at last_action_date cute_installation_id]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[cute_installation]
  end

  private

  def update_last_action_date
    self.last_action_date = Time.current if changed?
  end
end
