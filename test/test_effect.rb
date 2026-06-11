# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../objects/effects'
require_relative '../objects/projects'
require_relative '../objects/rsk'

class Rsk::EffectTest < TestCase
  def test_adds_and_fetches
    effects = Rsk::Effects.new(test_pgsql, Rsk::Projects.new(test_pgsql, 'jeff053').add("test#{rand(99_999)}"))
    effect = effects.get(effects.add('the business will halt'))
    refute_predicate(effect, :positive?)
    effect.polarize(true)
    assert_predicate(effect, :positive?)
  end
end
