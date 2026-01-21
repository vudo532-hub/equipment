# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StrongPasswordValidator do
  let(:validator) { described_class.new(attributes: [:password]) }

  # Test class to validate
  let(:test_class) do
    Class.new do
      include ActiveModel::Validations
      attr_accessor :password, :email

      validates :password, strong_password: true

      def initialize(password: nil, email: nil)
        @password = password
        @email = email
      end
    end
  end

  describe 'validation rules' do
    context 'with minimum length' do
      it 'rejects passwords shorter than 6 characters' do
        record = test_class.new(password: 'Ab1')
        expect(record).not_to be_valid
        expect(record.errors[:password].join).to include('короткий')
      end

      it 'accepts passwords with 6 or more characters' do
        record = test_class.new(password: 'Abcde1')
        # May fail due to sequential, but not length
        errors = record.tap(&:valid?).errors[:password]
        expect(errors.join).not_to include('короткий')
      end
    end

    context 'with uppercase requirement' do
      it 'rejects passwords without uppercase letters' do
        record = test_class.new(password: 'abcdef1')
        expect(record).not_to be_valid
        expect(record.errors[:password].join).to include('заглавн')
      end

      it 'accepts passwords with uppercase letters' do
        record = test_class.new(password: 'Secur1e')
        errors = record.tap(&:valid?).errors[:password]
        expect(errors.join).not_to include('заглавн')
      end

      it 'accepts cyrillic uppercase letters' do
        record = test_class.new(password: 'Пароль1')
        errors = record.tap(&:valid?).errors[:password]
        expect(errors.join).not_to include('заглавн')
      end
    end

    context 'with lowercase requirement' do
      it 'rejects passwords without lowercase letters' do
        record = test_class.new(password: 'ABCDEF1')
        expect(record).not_to be_valid
        expect(record.errors[:password].join).to include('строчн')
      end

      it 'accepts passwords with lowercase letters' do
        record = test_class.new(password: 'ABCdef1')
        errors = record.tap(&:valid?).errors[:password]
        expect(errors.join).not_to include('строчн')
      end
    end

    context 'with number requirement' do
      it 'rejects passwords without numbers' do
        record = test_class.new(password: 'Abcdefgh')
        expect(record).not_to be_valid
        expect(record.errors[:password].join).to include('цифр')
      end

      it 'accepts passwords with numbers' do
        record = test_class.new(password: 'Secure1e')
        errors = record.tap(&:valid?).errors[:password]
        expect(errors.join).not_to include('цифр')
      end
    end

    context 'with repeating characters check' do
      it 'rejects passwords with 3+ same characters in a row' do
        record = test_class.new(password: 'Paaassword1')
        expect(record).not_to be_valid
        expect(record.errors[:password].join).to include('одинаков')
      end

      it 'accepts passwords with only 2 same characters in a row' do
        record = test_class.new(password: 'Paassword1')
        errors = record.tap(&:valid?).errors[:password]
        expect(errors.join).not_to include('одинаков')
      end
    end

    context 'with sequential characters check' do
      it 'rejects passwords with numeric sequences' do
        %w[Abc123def Abc234def Abc456def].each do |pwd|
          record = test_class.new(password: pwd)
          expect(record).not_to be_valid
          expect(record.errors[:password].join).to include('последовательн')
        end
      end

      it 'rejects passwords with alphabetic sequences' do
        %w[Xyzabc1 Xyzqwe1 Qwerty1].each do |pwd|
          record = test_class.new(password: pwd)
          expect(record).not_to be_valid
          expect(record.errors[:password].join).to include('последовательн')
        end
      end

      it 'accepts passwords without sequential patterns' do
        record = test_class.new(password: 'Secure1Pass')
        errors = record.tap(&:valid?).errors[:password]
        expect(errors.join).not_to include('последовательн')
      end
    end

    context 'with common passwords check' do
      it 'rejects common passwords' do
        %w[Password1 Qwerty12 Admin123].each do |pwd|
          record = test_class.new(password: pwd)
          expect(record).not_to be_valid
          expect(record.errors[:password].join).to match(/простой|часто|последовательн/i)
        end
      end
    end

    context 'with email check' do
      it 'rejects passwords containing email username' do
        record = test_class.new(password: 'JohnDoe1', email: 'johndoe@example.com')
        expect(record).not_to be_valid
        expect(record.errors[:password].join).to include('email')
      end

      it 'accepts passwords not containing email username' do
        record = test_class.new(password: 'Secure1Pass', email: 'johndoe@example.com')
        errors = record.tap(&:valid?).errors[:password]
        expect(errors.join).not_to include('email')
      end

      it 'ignores short email usernames (2 chars or less)' do
        record = test_class.new(password: 'Ab12345', email: 'ab@example.com')
        errors = record.tap(&:valid?).errors[:password]
        expect(errors.join).not_to include('email')
      end
    end
  end

  describe 'loading weak passwords from file' do
    let(:weak_passwords_file) { Rails.root.join('db/fixtures/weak_passwords.json') }

    it 'loads weak passwords from JSON file' do
      expect(File).to exist(weak_passwords_file)
      data = JSON.parse(File.read(weak_passwords_file))
      expect(data).to have_key('weak_passwords')
      expect(data).to have_key('examples_for_testing')
    end

    it 'rejects common weak passwords from file' do
      data = JSON.parse(File.read(weak_passwords_file))
      common_weak = data.dig('weak_passwords', 'categories', 'common_weak', 'examples')

      # These should be rejected as-is or with minor modifications
      %w[password123 qwerty123 admin123].each do |pwd|
        modified_pwd = pwd.capitalize
        record = test_class.new(password: modified_pwd)
        expect(record).not_to be_valid, "Expected '#{modified_pwd}' to be invalid"
      end
    end
  end

  describe 'valid passwords' do
    let(:valid_passwords) do
      file_path = Rails.root.join('db/fixtures/weak_passwords.json')
      JSON.parse(File.read(file_path))['examples_for_testing']['valid_passwords']
    end

    it 'accepts all valid passwords from fixtures' do
      valid_passwords.each do |pwd|
        record = test_class.new(password: pwd)
        expect(record).to be_valid, "Expected '#{pwd}' to be valid, but got: #{record.errors[:password].join(', ')}"
      end
    end
  end
end
