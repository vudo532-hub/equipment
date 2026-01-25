class RepairBatchItem < ApplicationRecord
  # Associations
  belongs_to :repair_batch

  # Validations
  validates :equipment_type, presence: true
  validates :equipment_id, presence: true
  validates :system, presence: true

  # Scopes
  scope :by_system, ->(system) { where(system: system) if system.present? }
  scope :by_serial, ->(serial) { where(serial_number: serial) if serial.present? }

  # Полиморфное получение оборудования
  def equipment
    equipment_type.constantize.find_by(id: equipment_id)
  end

  # Ransack
  def self.ransackable_attributes(auth_object = nil)
    %w[system serial_number model inventory_number terminal installation_name created_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[repair_batch]
  end
end
