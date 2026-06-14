# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

class Rsk::PlansTest < Minitest::Test
  def test_adds_and_fetches
    _login, pid = make_project(test_pgsql)
    rid = make_risk(test_pgsql, pid)
    plans = Rsk::Plans.new(test_pgsql, pid)
    text = 'we make backups'
    id = plans.add(rid, text)
    plans.get(id, rid).schedule = '01-01-2001'
    assert_predicate(id, :positive?)
    assert_equal(1, plans.count)
    refute_empty(plans.fetch)
    assert(plans.fetch.any? { |p| p[:text] == text })
    plans.get(id, rid).complete
  end
end
