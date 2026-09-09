# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'

class Rsk::Trimmed
  def initialize(text, max)
    @text = text
    @max = max
  end

  def to_s
    text = @text.to_s
    return text if units(text) <= @max
    head = +''
    room = @max
    text.each_char do |c|
      width = c.ord > 0xFFFF ? 2 : 1
      break if width > room
      head << c
      room -= width
    end
    stop = head.rindex("\n")
    "#{stop.nil? ? head : head[0...stop]}..."
  end

  private

  def units(text)
    text.each_char.sum { |c| c.ord > 0xFFFF ? 2 : 1 }
  end
end
