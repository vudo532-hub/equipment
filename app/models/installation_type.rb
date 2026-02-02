# frozen_string_literal: true

class InstallationType < ApplicationRecord
  # Validations
  validates :system, presence: true, inclusion: { in: %w[cute fids zamar] }
  validates :name, presence: true, uniqueness: { scope: :system }
  validates :code, presence: true, uniqueness: { scope: :system }

  # Associations
  has_many :cute_installations, foreign_key: "installation_type_ref_id", dependent: :nullify
  has_many :fids_installations, foreign_key: "installation_type_ref_id", dependent: :nullify
  has_many :zamar_installations, foreign_key: "installation_type_ref_id", dependent: :nullify

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_system, ->(system) { where(system: system) }
  scope :ordered, -> { order(:position, :name) }

  # Callbacks
  before_validation :generate_code, if: -> { code.blank? && name.present? }

  def to_s
    name
  end

  def installation_count
    case system
    when "cute"
      CuteInstallation.where(installation_type_ref_id: id).count
    when "fids"
      FidsInstallation.where(installation_type_ref_id: id).count
    when "zamar"
      ZamarInstallation.where(installation_type_ref_id: id).count
    else
      0
    end
  end

  def can_destroy?
    installation_count.zero?
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
