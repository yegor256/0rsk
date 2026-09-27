# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'securerandom'
require_relative 'test__helper'

require_relative '../objects/plans'

class Rsk::PlansDuplicateTest < TestCase
  def test_refuses_a_plan_that_is_already_there
    project = test_project
    part = test_risk(project: project)
    plans = Rsk::Plans.new(test_pgsql, project)
    text = "plan #{SecureRandom.hex(8)}"
    plans.add(part, text)
    e = assert_raises(Rsk::Urror) { plans.add(part, text) }
    assert_includes(e.message, text, e.message)
  end
end
