# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FidsEquipment, type: :model do
  describe 'associations' do
    it { should belong_to(:user).optional }
    it { should belong_to(:fids_installation).optional }
  end

  describe 'validations' do
    subject { build(:fids_equipment) }

    it { should validate_presence_of(:equipment_type) }
    it { should validate_length_of(:equipment_type).is_at_most(100) }
    it { should validate_presence_of(:inventory_number) }
    it { should validate_length_of(:inventory_number).is_at_most(100) }
    it { should validate_length_of(:equipment_model).is_at_most(255) }
    it { should validate_length_of(:serial_number).is_at_most(100) }
    it { should validate_length_of(:note).is_at_most(2000) }

    it 'validates uniqueness of inventory_number globally' do
      create(:fids_equipment, inventory_number: 'INV-001')
      equipment = build(:fids_equipment, inventory_number: 'INV-001')
      expect(equipment).not_to be_valid
    end
  end

  describe 'enums' do
    it 'defines status enum with valid values' do
      expect(FidsEquipment.statuses.keys).to include(
        'active', 'maintenance', 'waiting_repair', 'ready_to_dispatch',
        'decommissioned', 'transferred', 'with_note'
      )
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }

    describe '.not_decommissioned' do
      it 'excludes decommissioned equipment' do
        active = create(:fids_equipment, user: user, status: :active)
        decommissioned = create(:fids_equipment, user: user, status: :decommissioned)
        
        expect(FidsEquipment.not_decommissioned).to include(active)
        expect(FidsEquipment.not_decommissioned).not_to include(decommissioned)
      end
    end
  end

  describe 'factory' do
    it 'creates valid equipment' do
      expect(build(:fids_equipment)).to be_valid
    end

    it 'creates valid equipment without installation' do
      expect(build(:fids_equipment, :without_installation)).to be_valid
    end
  end
end
