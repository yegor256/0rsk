# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'

class Rsk::Markdown
  SPECIAL = ['\\', '_', '*', '`', '[', ']'].freeze

  def initialize(text)
    @text = text
  end

  def to_s
    @text.to_s.chars.map { |c| Rsk::Markdown::SPECIAL.include?(c) ? "\\#{c}" : c }.join
  end
end
