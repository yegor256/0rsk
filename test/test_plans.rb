# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../objects/causes'
require_relative '../objects/effects'
require_relative '../objects/plans'
require_relative '../objects/projects'
require_relative '../objects/risks'
require_relative '../objects/rsk'
require_relative '../objects/triples'

class Rsk::PlansTest < TestCase
  def test_adds_and_fetches
    pid = test_project
    rid = test_risk(project: pid)
    plans = Rsk::Plans.new(test_pgsql, pid)
    text = 'we make backups'
    id = plans.add(rid, text)
    plans.get(id, rid).reschedule('01-01-2001')
    assert_predicate(id, :positive?)
    assert_equal(1, plans.count)
    refute_empty(plans.fetch)
    assert(plans.fetch.any? { |p| p[:text] == text })
    plans.get(id, rid).complete
  end

  def test_fetch_no_duplicates
    pid = test_project
    cid = test_cause(project: pid)
    eid = test_effect(project: pid)
    triples = Rsk::Triples.new(test_pgsql, pid)
    triples.add(cid, test_risk(project: pid), eid)
    triples.add(cid, test_risk(project: pid), eid)
    plans = Rsk::Plans.new(test_pgsql, pid)
    plans.add(cid, 'mitigate it')
    assert_equal(1, plans.count)
    assert_equal(1, plans.fetch.length)
  end
end
