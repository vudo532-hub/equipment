# frozen_string_literal: true

# Custom validator for strong passwords
# Checks password against various security rules
class StrongPasswordValidator < ActiveModel::EachValidator
  WEAK_PASSWORDS_FILE = Rails.root.join('db/fixtures/weak_passwords.json')

  # Patterns for validation
  HAS_UPPERCASE = /[A-ZА-ЯЁ]/.freeze
  HAS_LOWERCASE = /[a-zа-яё]/.freeze
  HAS_NUMBER = /\d/.freeze
  REPEATING_CHARS = /(.)\1{2,}/.freeze # Three or more same characters in a row
  SEQUENTIAL_PATTERNS = %w[
    012 123 234 345 456 567 678 789 890
    abc bcd cde def efg fgh ghi hij ijk jkl klm lmn mno nop opq pqr qrs rst stu tuv uvw vwx wxy xyz
    абв бвг вгд где деж ежз жзи зий ийк йкл клм лмн мно ноп опр прс рст сту туф уфх фхц хцч цчш чшщ
    qwe wer ert rty tyu yui uio iop asd sdf dfg fgh ghj hjk jkl zxc xcv cvb vbn bnm
  ].freeze

  def validate_each(record, attribute, value)
    return if value.blank?

    errors = []

    # Check minimum length (Devise handles this, but we double-check)
    errors << :too_short if value.length < 6

    # Check for uppercase letter
    errors << :no_uppercase unless value.match?(HAS_UPPERCASE)

    # Check for lowercase letter
    errors << :no_lowercase unless value.match?(HAS_LOWERCASE)

    # Check for number
    errors << :no_number unless value.match?(HAS_NUMBER)

    # Check for repeating characters
    errors << :has_repeating if value.match?(REPEATING_CHARS)

    # Check for sequential patterns
    errors << :has_sequential if contains_sequential?(value)

    # Check against common weak passwords
    errors << :too_common if common_password?(value)

    # Check if password contains email or username
    if record.respond_to?(:email) && record.email.present?
      email_name = record.email.split('@').first.downcase
      errors << :contains_email if value.downcase.include?(email_name) && email_name.length > 2
    end

    # Add error messages
    errors.each do |error|
      record.errors.add(attribute, error_message(error))
    end
  end

  private

  def contains_sequential?(value)
    downcase_value = value.downcase
    SEQUENTIAL_PATTERNS.any? { |pattern| downcase_value.include?(pattern) }
  end

  def common_password?(value)
    common_passwords.include?(value.downcase)
  end

  def common_passwords
    @common_passwords ||= load_common_passwords
  end

  def load_common_passwords
    return default_common_passwords unless File.exist?(WEAK_PASSWORDS_FILE)

    data = JSON.parse(File.read(WEAK_PASSWORDS_FILE))
    passwords = []

    # Collect all weak passwords from categories
    data.dig('weak_passwords', 'categories')&.each_value do |category|
      passwords.concat(category['examples'] || [])
    end

    # Also add common weak from examples_for_testing
    data.dig('examples_for_testing', 'invalid_passwords')&.each_value do |examples|
      passwords.concat(examples)
    end

    passwords.map(&:downcase).uniq
  rescue JSON::ParserError
    default_common_passwords
  end

  def default_common_passwords
    %w[
      password password1 password123 qwerty qwerty123
      123456 1234567 12345678 123456789 000000 111111
      admin admin123 letmein welcome monkey
    ]
  end

  def error_message(error)
    case error
    when :too_short
      'слишком короткий (минимум 6 символов)'
    when :no_uppercase
      'должен содержать хотя бы одну заглавную букву'
    when :no_lowercase
      'должен содержать хотя бы одну строчную букву'
    when :no_number
      'должен содержать хотя бы одну цифру'
    when :has_repeating
      'не должен содержать три одинаковых символа подряд'
    when :has_sequential
      'не должен содержать последовательные символы (123, abc, qwe)'
    when :too_common
      'слишком простой или часто используемый'
    when :contains_email
      'не должен содержать ваш email'
    else
      'не соответствует требованиям безопасности'
    end
  end
end
