# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiToken, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:api_token) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:token) }
    
    # Token is auto-generated, so we test that it's present after creation
    it 'has a token after creation' do
      token = create(:api_token)
      expect(token.token).to be_present
    end
  end

  describe 'callbacks' do
    describe '#generate_token' do
      it 'generates token before validation on create' do
        token = ApiToken.new(name: 'Test', user: create(:user))
        token.valid?
        expect(token.token).to be_present
        expect(token.token.length).to eq(64)
      end

      it 'does not regenerate token on update' do
        token = create(:api_token)
        original_token = token.token
        token.update(name: 'Updated Name')
        expect(token.token).to eq(original_token)
      end
    end
  end

  describe 'scopes' do
    describe '.active' do
      let(:user) { create(:user) }

      it 'includes tokens without expiration' do
        token = create(:api_token, user: user, expires_at: nil)
        expect(ApiToken.active).to include(token)
      end

      it 'includes tokens with future expiration' do
        token = create(:api_token, user: user, expires_at: 1.day.from_now)
        expect(ApiToken.active).to include(token)
      end

      it 'excludes expired tokens' do
        token = create(:api_token, :expired, user: user)
        expect(ApiToken.active).not_to include(token)
      end
    end
  end

  describe '#expired?' do
    it 'returns false when expires_at is nil' do
      token = build(:api_token, :never_expires)
      expect(token.expired?).to be false
    end

    it 'returns false when expires_at is in the future' do
      token = build(:api_token, expires_at: 1.day.from_now)
      expect(token.expired?).to be false
    end

    it 'returns true when expires_at is in the past' do
      token = build(:api_token, :expired)
      expect(token.expired?).to be true
    end
  end

  describe '#touch_last_used!' do
    it 'updates last_used_at timestamp' do
      token = create(:api_token)
      expect(token.last_used_at).to be_nil
      
      token.touch_last_used!
      
      expect(token.last_used_at).to be_present
      expect(token.last_used_at).to be_within(1.second).of(Time.current)
    end
  end

  describe 'factory' do
    it 'creates a valid token' do
      expect(build(:api_token)).to be_valid
    end

    it 'creates an expired token with trait' do
      token = build(:api_token, :expired)
      expect(token.expired?).to be true
    end
  end
end
