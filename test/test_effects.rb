# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

class Rsk::EffectsTest < Minitest::Test
  def test_adds_and_fetches
    _login, pid = make_project(test_pgsql)
    effects = Rsk::Effects.new(test_pgsql, pid)
    text = 'the client will be unhappy'
    eid = effects.add(text)
    assert_predicate(eid, :positive?)
    assert_equal(1, effects.count)
    assert(effects.fetch.any? { |e| e[:id] == eid })
    assert(effects.fetch.any? { |e| e[:text] == text })
  end
end
