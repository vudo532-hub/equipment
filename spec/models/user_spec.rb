# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:cute_installations).dependent(:nullify) }
    it { should have_many(:fids_installations).dependent(:nullify) }
    it { should have_many(:cute_equipments).dependent(:nullify) }
    it { should have_many(:fids_equipments).dependent(:nullify) }
    it { should have_many(:api_tokens).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:password) }
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_length_of(:first_name).is_at_most(100) }
    it { should validate_length_of(:last_name).is_at_most(100) }
  end

  describe 'Devise' do
    let(:user) { create(:user) }

    it 'authenticates with correct password' do
      expect(user.valid_password?('Secure1Pass')).to be true
    end

    it 'does not authenticate with wrong password' do
      expect(user.valid_password?('wrong')).to be false
    end
  end

  describe 'password validation' do
    let(:valid_attributes) do
      {
        email: 'test@example.com',
        first_name: 'Тест',
        last_name: 'Пользователь'
      }
    end

    context 'with weak passwords from fixtures' do
      let(:weak_passwords) do
        file_path = Rails.root.join('db/fixtures/weak_passwords.json')
        JSON.parse(File.read(file_path))['examples_for_testing']['invalid_passwords']
      end

      it 'rejects passwords that are too short' do
        weak_passwords['too_short'].each do |pwd|
          user = User.new(valid_attributes.merge(password: pwd, password_confirmation: pwd))
          expect(user).not_to be_valid
          expect(user.errors[:password].join).to match(/короткий|символов/i)
        end
      end

      it 'rejects passwords without uppercase letters' do
        weak_passwords['no_uppercase'].each do |pwd|
          user = User.new(valid_attributes.merge(password: pwd, password_confirmation: pwd))
          expect(user).not_to be_valid
          expect(user.errors[:password].join).to match(/заглавн/i)
        end
      end

      it 'rejects passwords without lowercase letters' do
        weak_passwords['no_lowercase'].each do |pwd|
          user = User.new(valid_attributes.merge(password: pwd, password_confirmation: pwd))
          expect(user).not_to be_valid
          expect(user.errors[:password].join).to match(/строчн/i)
        end
      end

      it 'rejects passwords without numbers' do
        weak_passwords['no_numbers'].each do |pwd|
          user = User.new(valid_attributes.merge(password: pwd, password_confirmation: pwd))
          expect(user).not_to be_valid
          expect(user.errors[:password].join).to match(/цифр/i)
        end
      end

      it 'rejects passwords with sequential characters' do
        weak_passwords['sequential'].each do |pwd|
          user = User.new(valid_attributes.merge(password: pwd, password_confirmation: pwd))
          expect(user).not_to be_valid
          expect(user.errors[:password].join).to match(/последовательн/i)
        end
      end

      it 'rejects passwords with repeating characters' do
        weak_passwords['repeating'].each do |pwd|
          user = User.new(valid_attributes.merge(password: pwd, password_confirmation: pwd))
          expect(user).not_to be_valid
          expect(user.errors[:password].join).to match(/одинаков|повтор/i)
        end
      end

      it 'rejects common weak passwords' do
        weak_passwords['common'].each do |pwd|
          user = User.new(valid_attributes.merge(password: pwd, password_confirmation: pwd))
          expect(user).not_to be_valid
        end
      end
    end

    context 'with valid passwords from fixtures' do
      let(:valid_passwords) do
        file_path = Rails.root.join('db/fixtures/weak_passwords.json')
        JSON.parse(File.read(file_path))['examples_for_testing']['valid_passwords']
      end

      it 'accepts strong passwords' do
        valid_passwords.each do |pwd|
          user = User.new(valid_attributes.merge(password: pwd, password_confirmation: pwd))
          expect(user).to be_valid, "Expected '#{pwd}' to be valid, but got errors: #{user.errors.full_messages.join(', ')}"
        end
      end
    end

    context 'password containing email' do
      it 'rejects password that contains email username' do
        user = User.new(
          email: 'johndoe@example.com',
          first_name: 'John',
          last_name: 'Doe',
          password: 'Johndoe1Pass',
          password_confirmation: 'Johndoe1Pass'
        )
        expect(user).not_to be_valid
        expect(user.errors[:password].join).to match(/email/i)
      end
    end
  end

  describe 'roles' do
    it 'has viewer role by default' do
      user = User.new
      expect(user.role).to eq('viewer')
    end

    it 'can be assigned different roles' do
      user = create(:user, role: :admin)
      expect(user).to be_admin
    end

    describe '#can_edit?' do
      it 'returns false for viewer' do
        user = build(:user, role: :viewer)
        expect(user.can_edit?).to be false
      end

      it 'returns true for editor' do
        user = build(:user, role: :editor)
        expect(user.can_edit?).to be true
      end

      it 'returns true for manager' do
        user = build(:user, role: :manager)
        expect(user.can_edit?).to be true
      end

      it 'returns true for admin' do
        user = build(:user, role: :admin)
        expect(user.can_edit?).to be true
      end
    end

    describe '#can_manage?' do
      it 'returns false for viewer' do
        user = build(:user, role: :viewer)
        expect(user.can_manage?).to be false
      end

      it 'returns false for editor' do
        user = build(:user, role: :editor)
        expect(user.can_manage?).to be false
      end

      it 'returns true for manager' do
        user = build(:user, role: :manager)
        expect(user.can_manage?).to be true
      end

      it 'returns true for admin' do
        user = build(:user, role: :admin)
        expect(user.can_manage?).to be true
      end
    end
  end

  describe '#full_name' do
    it 'returns first and last name combined' do
      user = build(:user, first_name: 'Иван', last_name: 'Петров')
      expect(user.full_name).to eq('Иван Петров')
    end
  end

  describe '#initials' do
    it 'returns initials from first and last name' do
      user = build(:user, first_name: 'Иван', last_name: 'Петров')
      expect(user.initials).to eq('ИП')
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
