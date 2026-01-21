# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CuteEquipment, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:cute_installation).optional }
  end

  describe 'validations' do
    subject { build(:cute_equipment) }

    it { should validate_presence_of(:equipment_type) }
    it { should validate_length_of(:equipment_type).is_at_most(100) }
    it { should validate_presence_of(:inventory_number) }
    it { should validate_length_of(:inventory_number).is_at_most(100) }
    it { should validate_length_of(:equipment_model).is_at_most(255) }
    it { should validate_length_of(:serial_number).is_at_most(100) }
    it { should validate_length_of(:note).is_at_most(2000) }

    it 'validates uniqueness of inventory_number within user scope' do
      user = create(:user)
      create(:cute_equipment, user: user, inventory_number: 'INV-001')
      duplicate = build(:cute_equipment, user: user, inventory_number: 'INV-001')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:inventory_number]).to include('уже существует')
    end

    it 'allows same inventory_number for different users' do
      user1 = create(:user)
      user2 = create(:user)
      create(:cute_equipment, user: user1, inventory_number: 'INV-001')
      equipment = build(:cute_equipment, user: user2, inventory_number: 'INV-001')
      expect(equipment).to be_valid
    end
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(active: 0, inactive: 1, maintenance: 2, archived: 3) }
  end

  describe 'scopes' do
    let(:user) { create(:user) }

    describe '.not_archived' do
      it 'excludes archived equipment' do
        active = create(:cute_equipment, user: user, status: :active)
        archived = create(:cute_equipment, user: user, status: :archived)
        
        expect(CuteEquipment.not_archived).to include(active)
        expect(CuteEquipment.not_archived).not_to include(archived)
      end
    end

    describe '.by_status' do
      it 'filters by status' do
        active = create(:cute_equipment, user: user, status: :active)
        inactive = create(:cute_equipment, user: user, status: :inactive)
        
        expect(CuteEquipment.by_status(:active)).to include(active)
        expect(CuteEquipment.by_status(:active)).not_to include(inactive)
      end
    end

    describe '.search' do
      it 'searches by equipment_type' do
        eq1 = create(:cute_equipment, user: user, equipment_type: 'Printer')
        eq2 = create(:cute_equipment, user: user, equipment_type: 'Scanner')
        
        expect(CuteEquipment.search('Printer')).to include(eq1)
        expect(CuteEquipment.search('Printer')).not_to include(eq2)
      end

      it 'searches by inventory_number' do
        eq1 = create(:cute_equipment, user: user, inventory_number: 'ABC-123')
        eq2 = create(:cute_equipment, user: user, inventory_number: 'XYZ-789')
        
        expect(CuteEquipment.search('ABC')).to include(eq1)
        expect(CuteEquipment.search('ABC')).not_to include(eq2)
      end
    end
  end

  describe 'callbacks' do
    it 'sets last_action_date on save' do
      equipment = build(:cute_equipment, last_action_date: nil)
      equipment.save
      expect(equipment.last_action_date).to be_present
    end
  end

  describe '#to_s' do
    it 'returns type and inventory_number' do
      equipment = build(:cute_equipment, equipment_type: 'Printer', inventory_number: 'INV-001')
      expect(equipment.to_s).to eq('Printer - INV-001')
    end
  end

  describe '#status_color' do
    it 'returns green for active' do
      equipment = build(:cute_equipment, status: :active)
      expect(equipment.status_color).to eq('green')
    end

    it 'returns gray for inactive' do
      equipment = build(:cute_equipment, status: :inactive)
      expect(equipment.status_color).to eq('gray')
    end

    it 'returns yellow for maintenance' do
      equipment = build(:cute_equipment, status: :maintenance)
      expect(equipment.status_color).to eq('yellow')
    end
  end

  describe 'factory' do
    it 'creates valid equipment' do
      expect(build(:cute_equipment)).to be_valid
    end

    it 'creates valid equipment without installation' do
      expect(build(:cute_equipment, :without_installation)).to be_valid
    end
  end
end
