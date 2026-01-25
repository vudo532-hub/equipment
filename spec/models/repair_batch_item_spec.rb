# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RepairBatchItem, type: :model do
  describe 'associations' do
    it { should belong_to(:repair_batch) }
  end

  describe 'validations' do
    it { should validate_presence_of(:equipment_type) }
    it { should validate_presence_of(:equipment_id) }
    it { should validate_presence_of(:system) }
  end

  describe 'polymorphic equipment access' do
    let(:user) { create(:user) }
    let(:repair_batch) { RepairBatch.create!(user: user, status: 'sent') }

    it 'can reference CuteEquipment' do
      cute_equipment = create(:cute_equipment, :maintenance)
      item = RepairBatchItem.create!(
        repair_batch: repair_batch,
        equipment_type: 'CuteEquipment',
        equipment_id: cute_equipment.id,
        system: 'cute',
        serial_number: cute_equipment.serial_number
      )
      
      expect(item.equipment).to eq(cute_equipment)
    end

    it 'can reference FidsEquipment' do
      fids_equipment = create(:fids_equipment, status: :maintenance)
      item = RepairBatchItem.create!(
        repair_batch: repair_batch,
        equipment_type: 'FidsEquipment',
        equipment_id: fids_equipment.id,
        system: 'fids',
        serial_number: fids_equipment.serial_number
      )
      
      expect(item.equipment).to eq(fids_equipment)
    end

    it 'can reference ZamarEquipment' do
      zamar_equipment = create(:zamar_equipment, status: :maintenance)
      item = RepairBatchItem.create!(
        repair_batch: repair_batch,
        equipment_type: 'ZamarEquipment',
        equipment_id: zamar_equipment.id,
        system: 'zamar',
        serial_number: zamar_equipment.serial_number
      )
      
      expect(item.equipment).to eq(zamar_equipment)
    end
  end

  describe 'denormalized data' do
    let(:user) { create(:user) }
    let(:repair_batch) { RepairBatch.create!(user: user, status: 'sent') }
    let(:equipment) { create(:cute_equipment, :maintenance) }

    it 'stores denormalized data for historical reference' do
      item = RepairBatchItem.create!(
        repair_batch: repair_batch,
        equipment_type: 'CuteEquipment',
        equipment_id: equipment.id,
        system: 'cute',
        serial_number: 'SN-12345',
        model: 'Test Model',
        terminal: 'T1',
        installation_name: 'Test Location'
      )

      expect(item.serial_number).to eq('SN-12345')
      expect(item.model).to eq('Test Model')
      expect(item.terminal).to eq('T1')
      expect(item.installation_name).to eq('Test Location')
    end
  end
end
