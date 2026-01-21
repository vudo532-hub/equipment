# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:cute_installations).dependent(:destroy) }
    it { should have_many(:fids_installations).dependent(:destroy) }
    it { should have_many(:cute_equipments).dependent(:destroy) }
    it { should have_many(:fids_equipments).dependent(:destroy) }
    it { should have_many(:api_tokens).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:password) }
  end

  describe 'Devise' do
    let(:user) { create(:user) }

    it 'authenticates with correct password' do
      expect(user.valid_password?('password123')).to be true
    end

    it 'does not authenticate with wrong password' do
      expect(user.valid_password?('wrong')).to be false
    end
  end

  describe 'factory' do
    it 'creates a valid user' do
      expect(build(:user)).to be_valid
    end

    it 'creates unique emails' do
      user1 = create(:user)
      user2 = create(:user)
      expect(user1.email).not_to eq(user2.email)
    end
  end
end
