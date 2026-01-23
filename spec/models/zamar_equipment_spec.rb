require 'rails_helper'

RSpec.describe ZamarEquipment, type: :model do
  describe 'validations' do
    subject { build(:zamar_equipment) }

    it { should validate_presence_of(:equipment_type) }
    it { should validate_presence_of(:inventory_number) }
    
    it 'validates uniqueness of inventory_number' do
      create(:zamar_equipment, inventory_number: 'INV-001')
      duplicate = build(:zamar_equipment, inventory_number: 'INV-001')
      expect(duplicate).not_to be_valid
    end
  end

  describe 'associations' do
    it { should belong_to(:zamar_installation).optional }
    it { should belong_to(:user).optional }
    it { should belong_to(:last_changed_by).class_name('User').optional }
  end

  describe 'enums' do
    it 'defines status enum with valid values' do
      expect(ZamarEquipment.statuses.keys).to include(
        'active', 'maintenance', 'waiting_repair', 'ready_to_dispatch',
        'decommissioned', 'transferred', 'with_note'
      )
    end

    it 'defines equipment_type enum with valid values' do
      expect(ZamarEquipment.equipment_types.keys).to include('dsm', 'dba', 'sbdo', 'gates', 'other')
    end
  end

  describe '#equipment_type_text' do
    it 'returns translated equipment type' do
      equipment = build(:zamar_equipment, equipment_type: 'dsm')
      expect(equipment.equipment_type_text).to eq('DSM')
    end
  end

  describe '#status_text' do
    it 'returns translated status' do
      equipment = build(:zamar_equipment, status: :active)
      expect(equipment.status_text).to eq('В работе')
    end
  end

  describe '#status_color' do
    context 'when active' do
      it 'returns green color classes' do
        equipment = build(:zamar_equipment, status: :active)
        expect(equipment.status_color).to eq('bg-green-100 text-green-800')
      end
    end

    context 'when maintenance' do
      it 'returns yellow color classes' do
        equipment = build(:zamar_equipment, status: :maintenance)
        expect(equipment.status_color).to eq('bg-yellow-100 text-yellow-800')
      end
    end

    context 'when decommissioned' do
      it 'returns red color classes' do
        equipment = build(:zamar_equipment, status: :decommissioned)
        expect(equipment.status_color).to eq('bg-red-100 text-red-800')
      end
    end
  end

  describe '#terminal' do
    let(:installation) { create(:zamar_installation, terminal: :terminal_a) }

    context 'when installation is present' do
      it 'delegates to installation' do
        equipment = build(:zamar_equipment, zamar_installation: installation)
        expect(equipment.terminal).to eq('terminal_a')
      end
    end

    context 'when installation is nil' do
      it 'returns nil' do
        equipment = build(:zamar_equipment, zamar_installation: nil)
        expect(equipment.terminal).to be_nil
      end
    end
  end

  describe '#terminal_name' do
    let(:installation) { create(:zamar_installation, terminal: :terminal_b) }

    context 'when installation is present' do
      it 'returns terminal name from installation' do
        equipment = build(:zamar_equipment, zamar_installation: installation)
        expect(equipment.terminal_name).to eq('B')
      end
    end

    context 'when installation is nil' do
      it 'returns nil' do
        equipment = build(:zamar_equipment, zamar_installation: nil)
        expect(equipment.terminal_name).to be_nil
      end
    end
  end

  describe 'auditing' do
    it 'tracks changes via audited' do
      equipment = create(:zamar_equipment, status: :active)
      equipment.update(status: :maintenance)

      expect(equipment.audits.count).to be >= 1
    end
  end

  describe 'ransackable attributes' do
    it 'allows searching by equipment_type' do
      expect(ZamarEquipment.ransackable_attributes).to include('equipment_type')
    end

    it 'allows searching by inventory_number' do
      expect(ZamarEquipment.ransackable_attributes).to include('inventory_number')
    end

    it 'allows searching by status' do
      expect(ZamarEquipment.ransackable_attributes).to include('status')
    end
  end

  describe 'ransackable associations' do
    it 'allows searching by zamar_installation' do
      expect(ZamarEquipment.ransackable_associations).to include('zamar_installation')
    end
  end
end
