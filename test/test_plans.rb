# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../objects/rsk'
require_relative '../objects/plans'
require_relative '../objects/projects'
require_relative '../objects/risks'
require_relative '../objects/effects'
require_relative '../objects/causes'
require_relative '../objects/triples'

# Test of Plans.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2026 Yegor Bugayenko
# License:: MIT
class Rsk::PlansTest < Minitest::Test
  def test_adds_and_fetches
    pid = Rsk::Projects.new(test_pgsql, 'jeff23').add("test#{rand(99_999)}")
    risks = Rsk::Risks.new(test_pgsql, pid)
    rid = risks.add('we may lose data')
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

  def test_schedule_daily
    pid = Rsk::Projects.new(test_pgsql, "dly#{rand(99_999)}").add("test#{rand(99_999)}")
    rid = Rsk::Risks.new(test_pgsql, pid).add('risk')
    plans = Rsk::Plans.new(test_pgsql, pid)
    id = plans.add(rid, 'plan')
    plan = plans.get(id, rid)
    plan.schedule = 'daily'
    assert_equal('daily', plan.schedule)
  end

  def test_schedule_weekly
    pid = Rsk::Projects.new(test_pgsql, "wkly#{rand(99_999)}").add("test#{rand(99_999)}")
    rid = Rsk::Risks.new(test_pgsql, pid).add('risk')
    plans = Rsk::Plans.new(test_pgsql, pid)
    id = plans.add(rid, 'plan')
    plan = plans.get(id, rid)
    plan.schedule = 'weekly'
    assert_equal('weekly', plan.schedule)
  end

  def test_schedule_monthly
    pid = Rsk::Projects.new(test_pgsql, "mnth#{rand(99_999)}").add("test#{rand(99_999)}")
    rid = Rsk::Risks.new(test_pgsql, pid).add('risk')
    plans = Rsk::Plans.new(test_pgsql, pid)
    id = plans.add(rid, 'plan')
    plan = plans.get(id, rid)
    plan.schedule = 'monthly'
    assert_equal('monthly', plan.schedule)
  end

  def test_schedule_quarterly
    pid = Rsk::Projects.new(test_pgsql, "qtr#{rand(99_999)}").add("test#{rand(99_999)}")
    rid = Rsk::Risks.new(test_pgsql, pid).add('risk')
    plans = Rsk::Plans.new(test_pgsql, pid)
    id = plans.add(rid, 'plan')
    plan = plans.get(id, rid)
    plan.schedule = 'quarterly'
    assert_equal('quarterly', plan.schedule)
  end

  def test_schedule_annually
    pid = Rsk::Projects.new(test_pgsql, "ann#{rand(99_999)}").add("test#{rand(99_999)}")
    rid = Rsk::Risks.new(test_pgsql, pid).add('risk')
    plans = Rsk::Plans.new(test_pgsql, pid)
    id = plans.add(rid, 'plan')
    plan = plans.get(id, rid)
    plan.schedule = 'annually'
    assert_equal('annually', plan.schedule)
  end

  def test_schedule_date
    pid = Rsk::Projects.new(test_pgsql, "dt#{rand(99_999)}").add("test#{rand(99_999)}")
    rid = Rsk::Risks.new(test_pgsql, pid).add('risk')
    plans = Rsk::Plans.new(test_pgsql, pid)
    id = plans.add(rid, 'plan')
    plan = plans.get(id, rid)
    plan.schedule = '25-12-2025'
    assert_equal('25-12-2025', plan.schedule)
  end

  def test_complete
    pid = Rsk::Projects.new(test_pgsql, "cmp#{rand(99_999)}").add("test#{rand(99_999)}")
    rid = Rsk::Risks.new(test_pgsql, pid).add('risk')
    plans = Rsk::Plans.new(test_pgsql, pid)
    id = plans.add(rid, 'plan')
    plan = plans.get(id, rid)
    plan.schedule = 'daily'
    plan.complete
    refute_nil(plan.schedule)
  end

  def test_detach
    pid = Rsk::Projects.new(test_pgsql, "det#{rand(99_999)}").add("test#{rand(99_999)}")
    eid = Rsk::Effects.new(test_pgsql, pid).add('effect')
    rid = Rsk::Risks.new(test_pgsql, pid).add('risk')
    cid = Rsk::Causes.new(test_pgsql, pid).add('cause')
    triples = Rsk::Triples.new(test_pgsql, pid)
    triples.add(cid, rid, eid)
    plans = Rsk::Plans.new(test_pgsql, pid)
    id = plans.add(eid, 'plan')
    plan = plans.get(id, eid)
    plan.detach
  end
end
