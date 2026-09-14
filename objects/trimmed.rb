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
    return text if text.length <= @max
    suffix = @max < 3 ? '.' * @max : '...'
    limit = @max - suffix.length
    chars = text.each_char.to_a
    stack = []
    escaped = false
    safe = 0
    line = 0
    openings = ['[', '(']
    closings = [[']', '['], [')', '(']]
    chars.first(limit).each_with_index do |char, idx|
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
      line = safe if char == "\n"
    end
    "#{chars.first(line.zero? ? safe : line).join}#{suffix}"
  end
end
