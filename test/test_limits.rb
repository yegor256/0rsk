# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../objects/limits'

class Rsk::LimitsTest < TestCase
  def test_counts_per_client
    limits = Rsk::Limits.new(max: 3)
    3.times { refute(limits.over?('1.1.1.1')) }
    assert(limits.over?('1.1.1.1'))
    refute(limits.over?('2.2.2.2'), 'one client must not block another one')
  end

  def test_forgets_old_hits
    limits = Rsk::Limits.new(max: 2, period: 60)
    now = Time.now.to_i
    2.times { limits.over?('1.1.1.1', now: now) }
    assert(limits.over?('1.1.1.1', now: now))
    refute(limits.over?('1.1.1.1', now: now + 61))
  end

  def test_survives_concurrent_hits
    limits = Rsk::Limits.new(max: 1_000_000)
    Array.new(8) do
      Thread.new { 100.times { limits.over?("ip#{Thread.current.object_id}") } }
    end.each(&:join)
    refute(limits.over?('1.1.1.1'))
  end
end
