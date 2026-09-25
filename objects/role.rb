# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'

class Rsk::Role
  def initialize(name = ENV.fetch('RSK_ROLE', nil))
    @name = name
  end

  def daemons?
    @name.nil? || @name == 'daemons'
  end
end
