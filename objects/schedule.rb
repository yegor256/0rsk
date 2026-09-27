# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'date'
require_relative 'rsk'
require_relative 'urror'

class Rsk::Schedule
  WORDS = %w[daily weekly biweekly monthly quarterly annually].freeze

  def initialize(text)
    @text = text
  end

  def to_s
    text = @text.to_s
    unless Rsk::Schedule::WORDS.include?(text) || /\A\d{2}-\d{2}-\d{4}\z/.match?(text)
      raise(Rsk::Urror, "Schedule can either be a word or a date DD-MM-YYYY: #{text.inspect}")
    end
    if /\A\d{2}-\d{2}-\d{4}\z/.match?(text)
      begin
        Date.strptime(text, '%d-%m-%Y')
      rescue Date::Error
        raise(Rsk::Urror, "There is no such date in the calendar: #{text.inspect}")
      end
    end
    text
  end
end
