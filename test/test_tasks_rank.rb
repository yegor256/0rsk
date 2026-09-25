# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'securerandom'
require_relative 'test__helper'

require_relative '../objects/plans'
require_relative '../objects/tasks'
require_relative '../objects/triples'

class Rsk::TasksRankTest < TestCase
  def test_shows_the_worst_triple_a_plan_belongs_to
    login = "u#{SecureRandom.hex(8)}"
    project = Rsk::Projects.new(test_pgsql, login).add("p#{SecureRandom.hex(8)}")
    effect = Rsk::Effects.new(test_pgsql, project).add("effect #{SecureRandom.hex(8)}")
    Rsk::Effects.new(test_pgsql, project).get(effect).weigh(9)
    triples = Rsk::Triples.new(test_pgsql, project)
    { 1 => 'low', 9 => 'high' }.each do |probability, name|
      risk = Rsk::Risks.new(test_pgsql, project).add("risk #{name} #{SecureRandom.hex(8)}")
      Rsk::Risks.new(test_pgsql, project).get(risk).weigh(probability)
      triples.add(Rsk::Causes.new(test_pgsql, project).add("cause #{name} #{SecureRandom.hex(8)}"), risk, effect)
    end
    plans = Rsk::Plans.new(test_pgsql, project)
    plans.get(plans.add(effect, "plan #{SecureRandom.hex(8)}"), effect)
      .reschedule((Time.now - (5 * 24 * 60 * 60)).strftime('%d-%m-%Y'))
    tasks = Rsk::Tasks.new(test_pgsql, login)
    tasks.create
    assert_equal(81, tasks.fetch[0][:rank], 'a task must show the worst triple it belongs to')
  end
end
