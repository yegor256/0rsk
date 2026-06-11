# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

class Rsk::EffectTest < Minitest::Test
  def test_adds_and_fetches
    _login, pid = make_project(test_pgsql)
    effects = Rsk::Effects.new(test_pgsql, pid)
    text = 'the business will halt'
    eid = effects.add(text)
    effect = effects.get(eid)
    refute_predicate(effect, :positive?)
    effect.positive = true
    assert_predicate(effect, :positive?)
  end
end
