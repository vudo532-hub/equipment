# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RepairBatch, type: :model do
  describe 'associations' do
    it { should belong_to(:user).optional }
    it { should have_many(:repair_batch_items).dependent(:destroy) }
  end

  describe 'validations' do
    subject { RepairBatch.new(user: create(:user), status: 'sent') }
    
    it 'validates uniqueness of repair_number' do
      batch1 = RepairBatch.create!(user: create(:user), status: 'sent')
      batch2 = RepairBatch.new(user: create(:user), status: 'sent', repair_number: batch1.repair_number)
      expect(batch2).not_to be_valid
      expect(batch2.errors[:repair_number]).to be_present
    end
  end

  describe 'callbacks' do
    describe '#generate_repair_number' do
      let(:user) { create(:user) }

      it 'generates repair number before create' do
        batch = RepairBatch.create!(user: user, status: 'sent')
        expect(batch.repair_number).to match(/^REP-\d{4}-\d{3}$/)
      end

      it 'generates sequential numbers within the same year' do
        batch1 = RepairBatch.create!(user: user, status: 'sent')
        batch2 = RepairBatch.create!(user: user, status: 'sent')

        year = Time.current.year
        expect(batch1.repair_number).to match(/^REP-#{year}-/)
        expect(batch2.repair_number).to match(/^REP-#{year}-/)

        num1 = batch1.repair_number.split('-').last.to_i
        num2 = batch2.repair_number.split('-').last.to_i
        expect(num2).to eq(num1 + 1)
      end
    end
  end

  describe '#status_color' do
    let(:user) { create(:user) }

    it 'returns correct color class for sent status' do
      batch = RepairBatch.new(user: user, status: 'sent')
      expect(batch.status_color).to include('yellow')
    end

    it 'returns correct color class for in_progress status' do
      batch = RepairBatch.new(user: user, status: 'in_progress')
      expect(batch.status_color).to include('blue')
    end

    it 'returns correct color class for received status' do
      batch = RepairBatch.new(user: user, status: 'received')
      expect(batch.status_color).to include('green')
    end

    it 'returns correct color class for closed status' do
      batch = RepairBatch.new(user: user, status: 'closed')
      expect(batch.status_color).to include('gray')
    end
  end

  describe '#status_text' do
    let(:user) { create(:user) }

    it 'returns human-readable status for sent' do
      batch = RepairBatch.new(user: user, status: 'sent')
      expect(batch.status_text).to eq('Отправлено в ремонт')
    end

    it 'returns human-readable status for in_progress' do
      batch = RepairBatch.new(user: user, status: 'in_progress')
      expect(batch.status_text).to eq('В ремонте')
    end

    it 'returns human-readable status for received' do
      batch = RepairBatch.new(user: user, status: 'received')
      expect(batch.status_text).to eq('Получено из ремонта')
    end

    it 'returns human-readable status for closed' do
      batch = RepairBatch.new(user: user, status: 'closed')
      expect(batch.status_text).to eq('Закрыто')
    end
  end
end
