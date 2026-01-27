class RepairBatch < ApplicationRecord
  # Associations
  belongs_to :user, optional: true
  has_many :repair_batch_items, dependent: :destroy

  # Validations
  validates :repair_number, presence: true, uniqueness: true

  # Callbacks
  before_validation :generate_repair_number, on: :create

  # Scopes
  scope :ordered, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) if status.present? }

  # Статусы
  STATUSES = {
    "sent" => "Отправлено в ремонт",
    "in_progress" => "В ремонте",
    "received" => "Получено из ремонта",
    "closed" => "Закрыто"
  }.freeze

  def self.statuses
    STATUSES.keys
  end

  def status_text
    STATUSES[status] || status.humanize
  end

  def status_color
    case status
    when "sent" then "bg-yellow-100 text-yellow-800"
    when "in_progress" then "bg-blue-100 text-blue-800"
    when "received" then "bg-green-100 text-green-800"
    when "closed" then "bg-gray-100 text-gray-800"
    else "bg-gray-100 text-gray-800"
    end
  end

  # Ransack
  def self.ransackable_attributes(auth_object = nil)
    %w[repair_number status created_at equipment_count]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[user repair_batch_items]
  end

  private

  def generate_repair_number
    return if repair_number.present?
    
    year = Time.current.year
    last_batch = RepairBatch.where("repair_number LIKE ?", "REP-#{year}-%").order(:repair_number).last
    
    if last_batch
      last_number = last_batch.repair_number.split("-").last.to_i
      self.repair_number = "REP-#{year}-#{format('%03d', last_number + 1)}"
    else
      self.repair_number = "REP-#{year}-001"
    end
  end
end
