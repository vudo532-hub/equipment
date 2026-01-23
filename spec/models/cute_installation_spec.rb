# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CuteInstallation, type: :model do
  describe 'associations' do
    it { should belong_to(:user).optional }
    it { should have_many(:cute_equipments).dependent(:nullify) }
  end

  describe 'validations' do
    subject { build(:cute_installation) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
    it { should validate_presence_of(:installation_type) }
    it { should validate_length_of(:installation_type).is_at_most(100) }
    it { should validate_length_of(:identifier).is_at_most(100) }

    it 'validates uniqueness of identifier globally' do
      create(:cute_installation, identifier: 'ID-001')
      duplicate = build(:cute_installation, identifier: 'ID-001')
      expect(duplicate).not_to be_valid
    end
  end

  describe 'scopes' do
    describe '.ordered' do
      it 'orders by name' do
        z_install = create(:cute_installation, name: 'Zebra')
        a_install = create(:cute_installation, name: 'Alpha')
        
        expect(CuteInstallation.ordered.first).to eq(a_install)
      end
    end

    describe '.by_type' do
      it 'filters by installation_type' do
        terminal = create(:cute_installation, installation_type: 'Terminal')
        gate = create(:cute_installation, installation_type: 'Gate')
        
        expect(CuteInstallation.by_type('Terminal')).to include(terminal)
        expect(CuteInstallation.by_type('Terminal')).not_to include(gate)
      end
    end

    describe '.search_by_name' do
      it 'searches by name (case insensitive)' do
        install = create(:cute_installation, name: 'Terminal A')
        
        expect(CuteInstallation.search_by_name('terminal')).to include(install)
        expect(CuteInstallation.search_by_name('TERMINAL')).to include(install)
      end
    end
  end

  describe '#to_s' do
    it 'returns the name' do
      installation = build(:cute_installation, name: 'Terminal 1')
      expect(installation.to_s).to eq('Terminal 1')
    end
  end

  describe '#equipment_count' do
    it 'returns count of associated equipments' do
      installation = create(:cute_installation)
      # Create equipment with different types to avoid validation error
      create(:cute_equipment, cute_installation: installation, equipment_type: 'keyboard')
      create(:cute_equipment, cute_installation: installation, equipment_type: 'scanner')
      create(:cute_equipment, cute_installation: installation, equipment_type: 'monitor')
      
      expect(installation.equipment_count).to eq(3)
    end
  end

  describe 'factory' do
    it 'creates a valid installation' do
      expect(build(:cute_installation)).to be_valid
    end
  end
end
