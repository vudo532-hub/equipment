class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :cute_installations, dependent: :destroy
  has_many :fids_installations, dependent: :destroy
  has_many :cute_equipments, dependent: :destroy
  has_many :fids_equipments, dependent: :destroy

  # For audited - track who made changes
  has_associated_audits

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
