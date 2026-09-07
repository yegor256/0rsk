# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'securerandom'
require_relative 'test__helper'

require_relative '../objects/plans'

class Rsk::PlanDetachTest < TestCase
  def test_refuses_a_part_the_plan_does_not_hang_on
    project = test_project
    risk = test_risk(project: project)
    cause = test_cause(project: project)
    plans = Rsk::Plans.new(test_pgsql, project)
    id = plans.add(risk, "plan #{SecureRandom.hex(8)}")
    assert_raises(Rsk::Urror) { plans.get(id, cause).detach }
    assert_equal(1, plans.count(query: ''), 'the plan must still be there')
  end

  def test_detaches_the_plan_it_hangs_on
    project = test_project
    risk = test_risk(project: project)
    plans = Rsk::Plans.new(test_pgsql, project)
    id = plans.add(risk, "plan #{SecureRandom.hex(8)}")
    plans.get(id, risk).detach
    assert_equal(0, plans.count(query: ''), 'the plan must be gone')
  end
end
