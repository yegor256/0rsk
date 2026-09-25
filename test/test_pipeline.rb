# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../objects/causes'
require_relative '../objects/effects'
require_relative '../objects/pipeline'
require_relative '../objects/plans'
require_relative '../objects/projects'
require_relative '../objects/risks'
require_relative '../objects/rsk'
require_relative '../objects/tasks'
require_relative '../objects/triples'

class Rsk::PipelineTest < TestCase
  def test_uses_calendar_year_for_annual_deadline
    assert_equal(
      Time.new(2025, 2, 28, 12, 0, 0, '+00:00'),
      Rsk::Pipeline.new(test_pgsql, 'unused').__send__(
        :deadline, Time.new(2024, 2, 29, 12, 0, 0, '+00:00'), 'annually'
      )
    )
  end

  def test_adds_and_fetches
    login = "bobby#{rand(99_999)}"
    project = Rsk::Projects.new(test_pgsql, login).add("testuu#{rand(99_999)}")
    cid = Rsk::Causes.new(test_pgsql, project).add('we have data')
    eid = Rsk::Effects.new(test_pgsql, project).add('business will stop')
    triples = Rsk::Triples.new(test_pgsql, project)
    triples.add(cid, Rsk::Risks.new(test_pgsql, project).add('we may lose it'), eid)
    triples.add(cid, Rsk::Risks.new(test_pgsql, project).add('we may lose it again'), eid)
    plans = Rsk::Plans.new(test_pgsql, project)
    pid = plans.add(eid, 'solve it!')
    plans.get(pid, eid).reschedule((Time.now - (5 * 24 * 60 * 60)).strftime('%d-%m-%Y'))
    pipeline = Rsk::Pipeline.new(test_pgsql, login)
    assert_equal(1, pipeline.fetch.count)
    assert(pipeline.fetch.any?(pid))
  end

  def test_fetches_the_higher_rank_first
    login = "bobbyR#{SecureRandom.hex(8)}"
    project = Rsk::Projects.new(test_pgsql, login).add("test#{SecureRandom.hex(8)}")
    plans = Rsk::Plans.new(test_pgsql, project)
    assert_equal(
      [1, 9].map { |weight| planned(project, plans, weight) }[1],
      Rsk::Pipeline.new(test_pgsql, login).fetch.first
    )
  end

  def test_keeps_the_fraction_of_the_average_rank
    login = "bobbyF#{SecureRandom.hex(8)}"
    project = Rsk::Projects.new(test_pgsql, login).add("test#{SecureRandom.hex(8)}")
    plans = Rsk::Plans.new(test_pgsql, project)
    planned(project, plans, 3)
    cid = Rsk::Causes.new(test_pgsql, project).add("we have data #{SecureRandom.hex(8)}")
    [[3, 3], [2, 5]].each do |probability, impact|
      rid = Rsk::Risks.new(test_pgsql, project).add("we may lose it #{SecureRandom.hex(8)}")
      eid = Rsk::Effects.new(test_pgsql, project).add("business will stop #{SecureRandom.hex(8)}")
      Rsk::Risks.new(test_pgsql, project).get(rid).weigh(probability)
      Rsk::Effects.new(test_pgsql, project).get(eid).weigh(impact)
      Rsk::Triples.new(test_pgsql, project).add(cid, rid, eid)
    end
    pid = plans.add(cid, 'solve it on average!')
    plans.get(pid, cid).reschedule((Time.now - (5 * 24 * 60 * 60)).strftime('%d-%m-%Y'))
    assert_equal(pid, Rsk::Pipeline.new(test_pgsql, login).fetch.first)
  end

  private

  def planned(project, plans, weight)
    rid = Rsk::Risks.new(test_pgsql, project).add("we may lose it #{weight}")
    eid = Rsk::Effects.new(test_pgsql, project).add("business will stop #{weight}")
    Rsk::Risks.new(test_pgsql, project).get(rid).weigh(weight)
    Rsk::Effects.new(test_pgsql, project).get(eid).weigh(weight)
    Rsk::Triples.new(test_pgsql, project).add(
      Rsk::Causes.new(test_pgsql, project).add("we have data #{weight}"), rid, eid
    )
    pid = plans.add(eid, "solve it #{weight}!")
    plans.get(pid, eid).reschedule((Time.now - (5 * 24 * 60 * 60)).strftime('%d-%m-%Y'))
    pid
  end
end
