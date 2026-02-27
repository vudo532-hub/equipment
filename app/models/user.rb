class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  # Roles
  enum :role, {
    viewer: 0,      # Только просмотр
    editor: 1,      # Редактирование
    manager: 2,     # Управление
    admin: 3        # Администратор
  }, default: :viewer

  # Associations
  has_many :cute_installations, dependent: :nullify
  has_many :fids_installations, dependent: :nullify
  has_many :cute_equipments, dependent: :nullify
  has_many :fids_equipments, dependent: :nullify
  has_many :api_tokens, dependent: :destroy

  # Validations
  validates :first_name, presence: true, length: { maximum: 100 }
  validates :last_name, presence: true, length: { maximum: 100 }
  validates :login, uniqueness: { allow_blank: true }

  # Strong password validation (only on create or when password is changed)
  # Skip for LDAP users (they have random passwords)
  validates :password, strong_password: true, if: :password_required_for_local_user?

  # For audited - track who made changes
  has_associated_audits

  # Ransack configuration for search functionality
  def self.ransackable_attributes(auth_object = nil)
    %w[id first_name last_name email login created_at updated_at role]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[api_tokens associated_audits cute_equipments cute_installations fids_equipments fids_installations]
  end

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

  # LDAP: Find or create user from LDAP entry
  def self.find_or_create_from_ldap(login, ldap_entry)
    email = ldap_entry[:mail]&.first&.downcase
    return nil if email.blank?

    user = find_by(login: login) || find_by(email: email)

    if user.nil?
      user = new(
        login: login,
        email: email,
        first_name: ldap_entry[:givenname]&.first || login,
        last_name: ldap_entry[:sn]&.first || "",
        password: SecureRandom.hex(32),
        role: :viewer
      )
      user.save!
    else
      user.update!(login: login) if user.login.blank?
    end

    user
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("LDAP: Failed to create/update user '#{login}': #{e.message}")
    nil
  end

  # Override Devise method to allow login by login field or email
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)&.strip&.downcase

    if login.present?
      where("login = ? OR LOWER(email) = ?", login, login).first
    else
      super
    end
  end

  # Is this a local user (not LDAP)?
  def local_user?
    login.blank? || login == "administrator"
  end

  private

  # Only require strong password for local (non-LDAP) users
  def password_required_for_local_user?
    password_required? && local_user?
  end
end
