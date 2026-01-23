require 'rails_helper'

RSpec.describe ZamarInstallation, type: :model do
  describe 'validations' do
    subject { build(:zamar_installation) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:installation_type) }
    
    it 'validates uniqueness of identifier' do
      create(:zamar_installation, identifier: 'ID-001')
      duplicate = build(:zamar_installation, identifier: 'ID-001')
      expect(duplicate).not_to be_valid
    end
  end

  describe 'associations' do
    it { should have_many(:zamar_equipments).dependent(:nullify) }
    it { should belong_to(:user).optional }
  end

  describe 'enums' do
    it 'defines terminal enum with valid values' do
      expect(ZamarInstallation.terminals.keys).to include('terminal_a', 'terminal_b', 'terminal_c', 'terminal_d', 'terminal_e', 'terminal_f')
    end
  end

  describe '#terminal_name' do
    context 'when terminal is set' do
      it 'returns formatted terminal name' do
        installation = build(:zamar_installation, terminal: :terminal_a)
        expect(installation.terminal_name).to eq('A')
      end

      it 'returns correct name for terminal_f' do
        installation = build(:zamar_installation, terminal: :terminal_f)
        expect(installation.terminal_name).to eq('F')
      end
    end

    context 'when terminal is nil' do
      it 'returns nil' do
        installation = build(:zamar_installation, terminal: nil)
        expect(installation.terminal_name).to be_nil
      end
    end
  end

  describe '#equipment_count' do
    let(:installation) { create(:zamar_installation) }

    context 'when no equipment attached' do
      it 'returns 0' do
        expect(installation.equipment_count).to eq(0)
      end
    end

    context 'when equipment is attached' do
      before do
        create_list(:zamar_equipment, 3, zamar_installation: installation)
      end

      it 'returns correct count' do
        expect(installation.equipment_count).to eq(3)
      end
    end
  end

  describe 'scopes' do
    describe '.ordered' do
      it 'orders by name ascending' do
        c = create(:zamar_installation, name: 'C Installation')
        a = create(:zamar_installation, name: 'A Installation')
        b = create(:zamar_installation, name: 'B Installation')

        expect(ZamarInstallation.ordered).to eq([a, b, c])
      end
    end
  end

  describe 'ransackable attributes' do
    it 'allows searching by name' do
      expect(ZamarInstallation.ransackable_attributes).to include('name')
    end

    it 'allows searching by terminal' do
      expect(ZamarInstallation.ransackable_attributes).to include('terminal')
    end

    it 'allows searching by installation_type' do
      expect(ZamarInstallation.ransackable_attributes).to include('installation_type')
    end
  end
end
