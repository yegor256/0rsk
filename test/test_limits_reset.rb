# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../0rsk'

class Rsk::LimitsResetTest < TestCase
  def test_uses_up_the_limiter_of_this_test
    10.times { Sinatra::Application.settings.rate_limits.over?('1.2.3.4') }
    assert(Sinatra::Application.settings.rate_limits.over?('1.2.3.4'))
  end

  def test_starts_with_a_limiter_nobody_used
    refute(Sinatra::Application.settings.rate_limits.over?('1.2.3.4'))
  end
end
