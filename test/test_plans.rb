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

class Rsk::PlansTest < Minitest::Test
  def test_adds_and_fetches
    pid = Rsk::Projects.new(test_pgsql, 'jeff23').add("test#{rand(99_999)}")
    rid = Rsk::Risks.new(test_pgsql, pid).add('we may lose data')
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
    pid = Rsk::Projects.new(test_pgsql, "dups#{rand(99_999)}").add("test#{rand(99_999)}")
    cid = Rsk::Causes.new(test_pgsql, pid).add('some cause')
    eid = Rsk::Effects.new(test_pgsql, pid).add('some effect')
    triples = Rsk::Triples.new(test_pgsql, pid)
    triples.add(cid, Rsk::Risks.new(test_pgsql, pid).add('risk one'), eid)
    triples.add(cid, Rsk::Risks.new(test_pgsql, pid).add('risk two'), eid)
    plans = Rsk::Plans.new(test_pgsql, pid)
    plans.add(cid, 'mitigate it')
    assert_equal(1, plans.count)
    assert_equal(1, plans.fetch.length)
  end
end
