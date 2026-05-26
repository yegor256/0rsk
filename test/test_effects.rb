# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../objects/rsk'
require_relative '../objects/effects'
require_relative '../objects/projects'

# Test of Effects.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2026 Yegor Bugayenko
# License:: MIT
class Rsk::EffectsTest < Minitest::Test
  def test_adds_and_fetches
    pid = Rsk::Projects.new(test_pgsql, 'jeff98').add('test')
    effects = Rsk::Effects.new(test_pgsql, pid)
    text = 'the business will halt'
    eid = effects.add(text)
    assert_predicate(eid, :positive?)
    assert_equal(1, effects.count)
    assert(effects.fetch.any? { |c| c[:text] == text })
  end

  def test_rejects_effect_from_another_project
    mine = Rsk::Projects.new(test_pgsql, "my#{rand(99_999)}").add("t#{rand(99_999)}")
    other = Rsk::Projects.new(test_pgsql, "you#{rand(99_999)}").add("t#{rand(99_999)}")
    eid = Rsk::Effects.new(test_pgsql, other).add('other effect')
    assert_raises(Rsk::Urror) { Rsk::Effects.new(test_pgsql, mine).get(eid) }
  end
end
