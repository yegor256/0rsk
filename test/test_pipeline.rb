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
