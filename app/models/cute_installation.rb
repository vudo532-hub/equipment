class CuteInstallation < ApplicationRecord
  # Audited
  audited associated_with: :user

  # Associations
  belongs_to :user
  has_many :cute_equipments, dependent: :nullify

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :installation_type, presence: true, length: { maximum: 100 }
  validates :identifier, length: { maximum: 100 },
                         uniqueness: { scope: :user_id, allow_blank: true }

  # Scopes
  scope :ordered, -> { order(:name) }
  scope :by_type, ->(type) { where(installation_type: type) if type.present? }
  scope :search_by_name, ->(query) { where("name ILIKE ?", "%#{query}%") if query.present? }

  # Callbacks
  strip_attributes
  nilify_blanks

  def to_s
    name
  end

  def equipment_count
    cute_equipments.count
  end
end
