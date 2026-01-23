class FidsInstallation < ApplicationRecord
  # Audited
  audited

  # Associations
  belongs_to :user, optional: true
  has_many :fids_equipments, dependent: :nullify

  # Enums
  enum :terminal, {
    terminal_a: 0,
    terminal_b: 1,
    terminal_c: 2,
    terminal_d: 3,
    terminal_e: 4,
    terminal_f: 5
  }, prefix: true

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :installation_type, presence: true, length: { maximum: 100 }
  validates :identifier, length: { maximum: 100 },
                         uniqueness: { allow_blank: true }

  # Scopes
  scope :ordered, -> { order(:name) }
  scope :by_type, ->(type) { where(installation_type: type) if type.present? }
  scope :by_terminal, ->(terminal) { where(terminal: terminal) if terminal.present? }
  scope :search_by_name, ->(query) { where("name ILIKE ?", "%#{query}%") if query.present? }

  # Callbacks
  strip_attributes
  nilify_blanks

  def to_s
    name
  end

  def equipment_count
    fids_equipments.count
  end

  def terminal_name
    return nil unless terminal
    terminal.to_s.split("_").last.upcase
  end

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[name installation_type identifier terminal created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[fids_equipments]
  end
end
