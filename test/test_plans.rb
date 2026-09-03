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
require 'securerandom'
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

  def test_schedule_daily
    pid = Rsk::Projects.new(
      test_pgsql,
      "dly#{SecureRandom.random_number(2_000_000_000) + 1}"
    ).add("test#{SecureRandom.random_number(2_000_000_000) + 1}")
    rid = Rsk::Risks.new(test_pgsql, pid).add('risk')
    plans = Rsk::Plans.new(test_pgsql, pid)
    plan = plans.get(plans.add(rid, 'plan'), rid)
    plan.reschedule('daily')
    assert_equal('daily', plan.schedule)
  end

  def test_schedule_weekly
    pid = Rsk::Projects.new(
      test_pgsql,
      "wkly#{SecureRandom.random_number(2_000_000_000) + 1}"
    ).add("test#{SecureRandom.random_number(2_000_000_000) + 1}")
    rid = Rsk::Risks.new(test_pgsql, pid).add('risk')
    plans = Rsk::Plans.new(test_pgsql, pid)
    plan = plans.get(plans.add(rid, 'plan'), rid)
    plan.reschedule('weekly')
    assert_equal('weekly', plan.schedule)
  end

  def test_schedule_monthly
    pid = Rsk::Projects.new(
      test_pgsql,
      "mnth#{SecureRandom.random_number(2_000_000_000) + 1}"
    ).add("test#{SecureRandom.random_number(2_000_000_000) + 1}")
    rid = Rsk::Risks.new(test_pgsql, pid).add('risk')
    plans = Rsk::Plans.new(test_pgsql, pid)
    plan = plans.get(plans.add(rid, 'plan'), rid)
    plan.reschedule('monthly')
    assert_equal('monthly', plan.schedule)
  end

  def test_schedule_quarterly
    pid = Rsk::Projects.new(
      test_pgsql,
      "qtr#{SecureRandom.random_number(2_000_000_000) + 1}"
    ).add("test#{SecureRandom.random_number(2_000_000_000) + 1}")
    rid = Rsk::Risks.new(test_pgsql, pid).add('risk')
    plans = Rsk::Plans.new(test_pgsql, pid)
    plan = plans.get(plans.add(rid, 'plan'), rid)
    plan.reschedule('quarterly')
    assert_equal('quarterly', plan.schedule)
  end

  def test_schedule_annually
    pid = Rsk::Projects.new(
      test_pgsql,
      "ann#{SecureRandom.random_number(2_000_000_000) + 1}"
    ).add("test#{SecureRandom.random_number(2_000_000_000) + 1}")
    rid = Rsk::Risks.new(test_pgsql, pid).add('risk')
    plans = Rsk::Plans.new(test_pgsql, pid)
    plan = plans.get(plans.add(rid, 'plan'), rid)
    plan.reschedule('annually')
    assert_equal('annually', plan.schedule)
  end

  def test_schedule_date
    pid = Rsk::Projects.new(
      test_pgsql,
      "dt#{SecureRandom.random_number(2_000_000_000) + 1}"
    ).add("test#{SecureRandom.random_number(2_000_000_000) + 1}")
    rid = Rsk::Risks.new(test_pgsql, pid).add('risk')
    plans = Rsk::Plans.new(test_pgsql, pid)
    plan = plans.get(plans.add(rid, 'plan'), rid)
    plan.reschedule('25-12-2025')
    assert_equal('25-12-2025', plan.schedule)
  end

  def test_complete
    pid = Rsk::Projects.new(
      test_pgsql,
      "cmp#{SecureRandom.random_number(2_000_000_000) + 1}"
    ).add("test#{SecureRandom.random_number(2_000_000_000) + 1}")
    rid = Rsk::Risks.new(test_pgsql, pid).add('risk')
    plans = Rsk::Plans.new(test_pgsql, pid)
    plan = plans.get(plans.add(rid, 'plan'), rid)
    plan.reschedule('daily')
    plan.complete
    refute_nil(plan.schedule)
  end

  def test_detach
    pid = Rsk::Projects.new(
      test_pgsql,
      "det#{SecureRandom.random_number(2_000_000_000) + 1}"
    ).add("test#{SecureRandom.random_number(2_000_000_000) + 1}")
    eid = Rsk::Effects.new(test_pgsql, pid).add('effect')
    Rsk::Triples.new(test_pgsql, pid).add(
      Rsk::Causes.new(test_pgsql, pid).add('cause'),
      Rsk::Risks.new(test_pgsql, pid).add('risk'), eid
    )
    plans = Rsk::Plans.new(test_pgsql, pid)
    plans.get(plans.add(eid, 'plan'), eid).detach
  end
end
