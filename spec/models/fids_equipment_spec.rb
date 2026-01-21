# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FidsEquipment, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
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
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(active: 0, inactive: 1, maintenance: 2, archived: 3) }
  end

  describe 'scopes' do
    let(:user) { create(:user) }

    describe '.not_archived' do
      it 'excludes archived equipment' do
        active = create(:fids_equipment, user: user, status: :active)
        archived = create(:fids_equipment, user: user, status: :archived)
        
        expect(FidsEquipment.not_archived).to include(active)
        expect(FidsEquipment.not_archived).not_to include(archived)
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
