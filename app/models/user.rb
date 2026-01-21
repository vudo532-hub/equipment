class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Roles
  enum :role, {
    viewer: 0,      # Только просмотр
    editor: 1,      # Редактирование
    manager: 2,     # Управление
    admin: 3        # Администратор
  }, default: :viewer

  # Associations
  has_many :cute_installations, dependent: :destroy
  has_many :fids_installations, dependent: :destroy
  has_many :cute_equipments, dependent: :destroy
  has_many :fids_equipments, dependent: :destroy
  has_many :api_tokens, dependent: :destroy

  # Validations
  validates :first_name, presence: true, length: { maximum: 100 }
  validates :last_name, presence: true, length: { maximum: 100 }

  # For audited - track who made changes
  has_associated_audits

  # Full name for display
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def initials
    "#{first_name.first}#{last_name.first}".upcase if first_name.present? && last_name.present?
  end

  # Role helpers
  def can_edit?
    editor? || manager? || admin?
  end

  def can_manage?
    manager? || admin?
  end

  # Role display name
  def role_name
    I18n.t("roles.#{role}", default: role.to_s.humanize)
  end

  # Statistics methods
  def cute_equipment_count
    cute_equipments.count
  end

  def fids_equipment_count
    fids_equipments.count
  end

  def cute_installations_count
    cute_installations.count
  end

  def fids_installations_count
    fids_installations.count
  end

  def cute_equipment_by_status
    cute_equipments.group(:status).count
  end

  def fids_equipment_by_status
    fids_equipments.group(:status).count
  end
end
