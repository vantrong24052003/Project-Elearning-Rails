# frozen_string_literal: true

class Question < ApplicationRecord
  belongs_to :course
  belongs_to :user

  has_many :quiz_questions
  has_many :quizzes, through: :quiz_questions

  enumerize :learning_goal, in: %i[remember understand apply analyze create other], default: :other
  enumerize :topic, in: %i[math physics chemistry biology history geography literature programming other],
                    default: :other
  enumerize :difficulty, in: %i[easy medium hard]
  enumerize :status, in: %i[active inactive deprecated], default: :active, scope: true, predicates: true

  validates :content, :options, :correct_option, :explanation, :difficulty, presence: true
  validate :validate_options_format

  private

  def validate_options_format
    return if options.blank?

    begin
      opts = options.is_a?(String) ? JSON.parse(options) : options

      if !opts.is_a?(Hash)
        errors.add(:options, "must be a valid JSON")
        return
      end

      errors.add(:options, "must have 4 options") if opts.size != 4
      errors.add(:options, "keys must be numbers 0-3") if !opts.keys.all? { |k| k.to_s.match?(/^[0-3]$/) }
      errors.add(:options, "values must be strings") if !opts.values.all? { |v| v.is_a?(String) }
      errors.add(:correct_option, "must exist in options") if correct_option.present? && !opts.key?(correct_option.to_s)
    rescue JSON::ParserError
      errors.add(:options, "must be a valid JSON")
    end
  end
end
