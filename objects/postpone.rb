# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'
require_relative 'urror'

class Rsk::Postpone
  PERIODS = { 'week' => 7 * 24 * 60 * 60, 'month' => 30 * 24 * 60 * 60, 'quarter' => 3 * 30 * 24 * 60 * 60 }.freeze

  def initialize(period)
    @period = period
  end

  def seconds
    Rsk::Postpone::PERIODS.fetch(@period) do
      raise(Rsk::Urror, "Unknown postpone period: #{@period.inspect}")
    end
  end
end
