# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../objects/rsk'
require_relative '../objects/projects'
require_relative '../objects/risks'
require_relative '../objects/plans'
require_relative '../objects/urror'

class Rsk::PlanTest < Minitest::Test
  def test_reads_schedule
    plan = make_plan
    assert_kind_of(String, plan.schedule)
  end

  def test_modifies_schedule
    plan = make_plan
    plan.schedule = 'weekly'
    assert_equal('weekly', plan.schedule)
    plan.schedule = '01-01-2030'
    assert_equal('01-01-2030', plan.schedule)
  end

  def test_rejects_invalid_schedule
    plan = make_plan
    assert_raises(Rsk::Urror) { plan.schedule = 'bad' }
  end

  def test_completes_word_schedule
    plan = make_plan
    plan.schedule = 'daily'
    plan.complete
    assert_kind_of(String, plan.schedule)
  end

  def test_completes_date_schedule_detaches
    pid = Rsk::Projects.new(test_pgsql, "planX#{rand(99_999)}").add("px#{rand(99_999)}")
    rid = Rsk::Risks.new(test_pgsql, pid).add('we may lose')
    plans = Rsk::Plans.new(test_pgsql, pid)
    id = plans.add(rid, 'backup')
    plan = plans.get(id, rid)
    orig_count = plans.count
    plan.schedule = '01-01-2001'
    plan.complete
    assert_equal(orig_count - 1, plans.count)
  end

  private

  def make_plan
    pid = Rsk::Projects.new(test_pgsql, "planT#{rand(99_999)}").add("pt#{rand(99_999)}")
    rid = Rsk::Risks.new(test_pgsql, pid).add('we may lose data')
    plans = Rsk::Plans.new(test_pgsql, pid)
    id = plans.add(rid, 'we make backups')
    plans.get(id, rid)
  end
end
