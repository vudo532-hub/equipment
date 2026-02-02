# frozen_string_literal: true

class EquipmentType < ApplicationRecord
  # Validations
  validates :system, presence: true, inclusion: { in: %w[cute fids zamar] }
  validates :name, presence: true, uniqueness: { scope: :system }
  validates :code, presence: true, uniqueness: { scope: :system }

  # Associations
  has_many :cute_equipments, foreign_key: "equipment_type_ref_id", dependent: :nullify
  has_many :fids_equipments, foreign_key: "equipment_type_ref_id", dependent: :nullify
  has_many :zamar_equipments, foreign_key: "equipment_type_ref_id", dependent: :nullify

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_system, ->(system) { where(system: system) }
  scope :ordered, -> { order(:position, :name) }

  # Callbacks
  before_validation :generate_code, if: -> { code.blank? && name.present? }

  def to_s
    name
  end

  def equipment_count
    case system
    when "cute"
      CuteEquipment.where(equipment_type_ref_id: id).count
    when "fids"
      FidsEquipment.where(equipment_type_ref_id: id).count
    when "zamar"
      ZamarEquipment.where(equipment_type_ref_id: id).count
    else
      0
    end
  end

  def can_destroy?
    equipment_count.zero?
  end

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[id system name code position active created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  private

  def generate_code
    self.code = name.parameterize.underscore
  end
end
