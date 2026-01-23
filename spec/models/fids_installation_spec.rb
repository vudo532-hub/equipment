# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FidsInstallation, type: :model do
  describe 'associations' do
    it { should belong_to(:user).optional }
    it { should have_many(:fids_equipments).dependent(:nullify) }
  end

  describe 'validations' do
    subject { build(:fids_installation) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
    it { should validate_presence_of(:installation_type) }
    it { should validate_length_of(:installation_type).is_at_most(100) }
    it { should validate_length_of(:identifier).is_at_most(100) }

    it 'validates uniqueness of identifier globally' do
      create(:fids_installation, identifier: 'ID-001')
      installation = build(:fids_installation, identifier: 'ID-001')
      expect(installation).not_to be_valid
    end
  end

  describe 'scopes' do
    describe '.ordered' do
      it 'orders by name' do
        z_install = create(:fids_installation, name: 'Zebra Display')
        a_install = create(:fids_installation, name: 'Alpha Display')
        
        expect(FidsInstallation.ordered.first).to eq(a_install)
      end
    end
  end

  describe '#to_s' do
    it 'returns the name' do
      installation = build(:fids_installation, name: 'Display A')
      expect(installation.to_s).to eq('Display A')
    end
  end

  describe '#equipment_count' do
    it 'returns count of associated equipments' do
      installation = create(:fids_installation)
      create_list(:fids_equipment, 3, fids_installation: installation)
      
      expect(installation.equipment_count).to eq(3)
    end
  end

  describe 'factory' do
    it 'creates a valid installation' do
      expect(build(:fids_installation)).to be_valid
    end
  end
end
