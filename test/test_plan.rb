# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../objects/plans'
require_relative '../objects/projects'
require_relative '../objects/risks'
require_relative '../objects/rsk'
require_relative '../objects/urror'

class Rsk::PlanTest < TestCase
  def test_reads_schedule
    assert_equal('weekly', with_plan.schedule)
  end

  def test_modifies_schedule
    plan = with_plan
    plan.reschedule('weekly')
    assert_equal('weekly', plan.schedule)
    plan.reschedule('01-01-2030')
    assert_equal('01-01-2030', plan.schedule)
  end

  def test_rejects_invalid_schedule
    plan = with_plan
    assert_raises(Rsk::Urror) { plan.reschedule('bad') }
  end

  def test_completes_word_schedule
    plan = with_plan(login: "planW#{SecureRandom.hex(8)}", title: "pw#{SecureRandom.hex(8)}")
    plan.reschedule('daily')
    plan.complete
    assert_equal(1, @plans.count)
  end

  def test_completes_date_schedule_detaches
    plan = with_plan(login: "planX#{SecureRandom.hex(8)}", title: "px#{SecureRandom.hex(8)}")
    plan.reschedule('01-01-2001')
    plan.complete
    assert_equal(0, @plans.count)
  end

  private

  def with_plan(login: "planT#{SecureRandom.hex(8)}", title: "pt#{SecureRandom.hex(8)}")
    pid = Rsk::Projects.new(test_pgsql, login).add(title)
    rid = Rsk::Risks.new(test_pgsql, pid).add('we may lose data')
    @plans = Rsk::Plans.new(test_pgsql, pid)
    @plans.get(@plans.add(rid, 'we make backups'), rid)
  end
end
