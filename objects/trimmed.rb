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
    head = text[0...@max]
    stop = head.rindex("\n")
    "#{stop.nil? ? head : head[0...stop]}..."
  end
end
