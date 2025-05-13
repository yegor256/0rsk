# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'rack/test'
require_relative 'test__helper'
require_relative '../objects/rsk'
require_relative '../objects/effects'
require_relative '../objects/projects'

# Test of Effect.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::EffectTest < Minitest::Test
  def test_adds_and_fetches
    pid = Rsk::Projects.new(test_pgsql, 'jeff053').add("test#{rand(99_999)}")
    effects = Rsk::Effects.new(test_pgsql, pid)
    text = 'the business will halt'
    eid = effects.add(text)
    effect = effects.get(eid)
    refute_predicate(effect, :positive?)
    effect.positive = true
    assert_predicate(effect, :positive?)
  end
end
