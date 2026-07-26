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
require_relative '../objects/tasks'
require_relative '../objects/triples'

class Rsk::PipelineTest < TestCase
  def test_adds_and_fetches
    login = "bobby#{rand(99_999)}"
    project = Rsk::Projects.new(fake_pgsql, login).add("testuu#{rand(99_999)}")
    cid = Rsk::Causes.new(fake_pgsql, project).add('we have data')
    eid = Rsk::Effects.new(fake_pgsql, project).add('business will stop')
    triples = Rsk::Triples.new(fake_pgsql, project)
    triples.add(cid, Rsk::Risks.new(fake_pgsql, project).add('we may lose it'), eid)
    triples.add(cid, Rsk::Risks.new(fake_pgsql, project).add('we may lose it again'), eid)
    plans = Rsk::Plans.new(fake_pgsql, project)
    pid = plans.add(eid, 'solve it!')
    plans.get(pid, eid).reschedule((Time.now - (5 * 24 * 60 * 60)).strftime('%d-%m-%Y'))
    pipeline = Rsk::Pipeline.new(fake_pgsql, login)
    assert_equal(1, pipeline.fetch.count)
    assert(pipeline.fetch.any?(pid))
  end
end
