# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'securerandom'
require_relative 'test__helper'

require_relative '../objects/plans'
require_relative '../objects/tasks'
require_relative '../objects/triples'

class Rsk::TasksCreateTest < TestCase
  def test_stops_at_the_threshold
    login = "u#{SecureRandom.hex(8)}"
    project = Rsk::Projects.new(test_pgsql, login).add("p#{SecureRandom.hex(8)}")
    effect = Rsk::Effects.new(test_pgsql, project).add("effect #{SecureRandom.hex(8)}")
    Rsk::Triples.new(test_pgsql, project).add(
      Rsk::Causes.new(test_pgsql, project).add("cause #{SecureRandom.hex(8)}"),
      Rsk::Risks.new(test_pgsql, project).add("risk #{SecureRandom.hex(8)}"),
      effect
    )
    plans = Rsk::Plans.new(test_pgsql, project)
    (Rsk::Tasks::THRESHOLD + 4).times do
      plans.get(plans.add(effect, "plan #{SecureRandom.hex(8)}"), effect)
        .reschedule((Time.now - (5 * 24 * 60 * 60)).strftime('%d-%m-%Y'))
    end
    tasks = Rsk::Tasks.new(test_pgsql, login)
    tasks.create
    assert_equal(Rsk::Tasks::THRESHOLD, tasks.count, 'no more than the threshold may be created')
    tasks.create
    assert_equal(Rsk::Tasks::THRESHOLD, tasks.count, 'a second run must add nothing')
  end
end
