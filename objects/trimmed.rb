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
    suffix = @max < 3 ? '.' * @max : '...'
    limit = @max - units(suffix)
    chars = text.each_char.to_a
    stack = []
    escaped = false
    safe = 0
    line = 0
    openings = ['[', '(']
    closings = [[']', '['], [')', '(']]
    room = limit
    chars.each_with_index do |char, idx|
      width = char.ord > 0xFFFF ? 2 : 1
      break if width > room
      room -= width
      if escaped
        escaped = false
      elsif char == '\\'
        escaped = true
      elsif openings.include?(char)
        stack << char
      elsif closings.include?([char, stack.last])
        stack.pop
      end
      next unless stack.empty? && !escaped
      safe = idx + 1
      line = idx if char == "\n"
    end
    "#{chars.first(line.zero? ? safe : line).join}#{suffix}"
  end

  private

  def units(text)
    text.each_char.sum { |c| c.ord > 0xFFFF ? 2 : 1 }
  end
end
