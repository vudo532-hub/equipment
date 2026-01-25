# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CuteEquipment, type: :model do
  describe 'associations' do
    it { should belong_to(:user).optional }
    it { should belong_to(:cute_installation).optional }
    it { should belong_to(:last_changed_by).class_name('User').optional }
  end

  describe 'validations' do
    subject { build(:cute_equipment) }

    it { should validate_presence_of(:equipment_type) }
    it { should validate_presence_of(:inventory_number) }
    it { should validate_presence_of(:serial_number) }

    it 'validates uniqueness of serial_number globally' do
      create(:cute_equipment, serial_number: 'SN-UNIQUE-001')
      duplicate = build(:cute_equipment, serial_number: 'SN-UNIQUE-001')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:serial_number]).to include('уже существует')
    end

    it 'validates uniqueness of inventory_number globally' do
      create(:cute_equipment, inventory_number: 'INV-001')
      duplicate = build(:cute_equipment, inventory_number: 'INV-001')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:inventory_number]).to include('уже существует')
    end

    describe 'unique_equipment_type_per_installation' do
      let(:installation) { create(:cute_installation) }
      let!(:existing_equipment) { create(:cute_equipment, equipment_type: 'boarding_pass_printer', cute_installation: installation) }

      context 'when non-admin user' do
        it 'does not allow duplicate equipment type in same installation' do
          new_equipment = build(:cute_equipment, equipment_type: 'boarding_pass_printer', cute_installation: installation)
          new_equipment.current_user_admin = false
          
          expect(new_equipment).not_to be_valid
          expect(new_equipment.errors[:base]).to include(match(/уже привязано/))
        end

        it 'allows same equipment type in different installation' do
          other_installation = create(:cute_installation)
          new_equipment = build(:cute_equipment, equipment_type: 'boarding_pass_printer', cute_installation: other_installation)
          new_equipment.current_user_admin = false
          
          expect(new_equipment).to be_valid
        end

        it 'allows different equipment type in same installation' do
          new_equipment = build(:cute_equipment, equipment_type: 'keyboard', cute_installation: installation)
          new_equipment.current_user_admin = false
          
          expect(new_equipment).to be_valid
        end
      end

      context 'when admin user' do
        it 'allows duplicate equipment type in same installation' do
          new_equipment = build(:cute_equipment, equipment_type: 'boarding_pass_printer', cute_installation: installation)
          new_equipment.current_user_admin = true
          
          expect(new_equipment).to be_valid
        end
      end
    end
  end

  describe 'enums' do
    it 'defines status enum with valid values' do
      expect(CuteEquipment.statuses.keys).to include(
        'active', 'maintenance', 'waiting_repair', 'ready_to_dispatch',
        'decommissioned', 'transferred', 'with_note'
      )
    end
  end

  describe 'scopes' do
    describe '.unassigned' do
      it 'returns equipment without installation' do
        assigned = create(:cute_equipment)
        unassigned = create(:cute_equipment, :without_installation)
        
        expect(CuteEquipment.unassigned).to include(unassigned)
        expect(CuteEquipment.unassigned).not_to include(assigned)
      end
    end
  end

  describe '.find_duplicate' do
    let(:installation) { create(:cute_installation) }
    let!(:equipment) { create(:cute_equipment, equipment_type: 'keyboard', cute_installation: installation) }

    it 'finds duplicate in same installation' do
      duplicate = CuteEquipment.find_duplicate('keyboard', installation.id)
      expect(duplicate).to eq(equipment)
    end

    it 'excludes specific equipment by id' do
      duplicate = CuteEquipment.find_duplicate('keyboard', installation.id, equipment.id)
      expect(duplicate).to be_nil
    end

    it 'returns nil when no duplicate exists' do
      duplicate = CuteEquipment.find_duplicate('scanner', installation.id)
      expect(duplicate).to be_nil
    end
  end

  describe '#terminal' do
    let(:installation) { create(:cute_installation, terminal: :terminal_a) }

    context 'when installation is present' do
      it 'delegates to installation' do
        equipment = build(:cute_equipment, cute_installation: installation)
        expect(equipment.terminal).to eq('terminal_a')
      end
    end

    context 'when installation is nil' do
      it 'returns nil' do
        equipment = build(:cute_equipment, cute_installation: nil)
        expect(equipment.terminal).to be_nil
      end
    end
  end

  describe '#terminal_name' do
    let(:installation) { create(:cute_installation, terminal: :terminal_b) }

    context 'when installation is present' do
      it 'returns terminal name from installation' do
        equipment = build(:cute_equipment, cute_installation: installation)
        expect(equipment.terminal_name).to eq('B')
      end
    end

    context 'when installation is nil' do
      it 'returns nil' do
        equipment = build(:cute_equipment, cute_installation: nil)
        expect(equipment.terminal_name).to be_nil
      end
    end
  end

  describe '#equipment_type_text' do
    it 'returns translated equipment type' do
      equipment = build(:cute_equipment, equipment_type: 'keyboard')
      expect(equipment.equipment_type_text).to eq('Клавиатура')
    end
  end

  describe '#status_text' do
    it 'returns translated status' do
      equipment = build(:cute_equipment, status: :active)
      expect(equipment.status_text).to eq('В работе')
    end
  end

  describe '#status_color' do
    it 'returns green classes for active' do
      equipment = build(:cute_equipment, status: :active)
      expect(equipment.status_color).to eq('bg-green-100 text-green-800')
    end

    it 'returns yellow classes for maintenance' do
      equipment = build(:cute_equipment, status: :maintenance)
      expect(equipment.status_color).to eq('bg-yellow-100 text-yellow-800')
    end

    it 'returns red classes for decommissioned' do
      equipment = build(:cute_equipment, status: :decommissioned)
      expect(equipment.status_color).to eq('bg-red-100 text-red-800')
    end
  end

  describe 'auditing' do
    it 'tracks changes via audited' do
      equipment = create(:cute_equipment, status: :active)
      equipment.update(status: :maintenance)

      expect(equipment.audits.count).to be >= 1
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
