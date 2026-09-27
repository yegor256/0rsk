# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'
require_relative 'urror'

module Rsk::PartText
  MAX_LENGTH = 160

  def self.validate(text)
    return if text.length <= MAX_LENGTH
    raise(Rsk::Urror, "Part text must not exceed #{MAX_LENGTH} characters")
  end
end
