# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../objects/effects'
require_relative '../objects/projects'
require_relative '../objects/rsk'

class Rsk::EffectsTest < TestCase
  def test_adds_and_fetches
    effects = Rsk::Effects.new(test_pgsql, Rsk::Projects.new(test_pgsql, 'jeff98').add('test'))
    text = 'the business will halt'
    assert_predicate(effects.add(text), :positive?)
    assert_equal(1, effects.count)
    assert(effects.fetch.any? { |c| c[:text] == text })
  end
end
