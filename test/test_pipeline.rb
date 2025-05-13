# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'rack/test'
require_relative 'test__helper'
require_relative '../objects/rsk'
require_relative '../objects/causes'
require_relative '../objects/risks'
require_relative '../objects/effects'
require_relative '../objects/projects'
require_relative '../objects/triples'
require_relative '../objects/tasks'
require_relative '../objects/plans'

# Test of Pipeline.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::PipelineTest < Minitest::Test
  def test_adds_and_fetches
    login = "bobby#{rand(99_999)}"
    project = Rsk::Projects.new(test_pgsql, login).add("testuu#{rand(99_999)}")
    cid = Rsk::Causes.new(test_pgsql, project).add('we have data')
    rid = Rsk::Risks.new(test_pgsql, project).add('we may lose it')
    rid2 = Rsk::Risks.new(test_pgsql, project).add('we may lose it again')
    eid = Rsk::Effects.new(test_pgsql, project).add('business will stop')
    triples = Rsk::Triples.new(test_pgsql, project)
    triples.add(cid, rid, eid)
    triples.add(cid, rid2, eid)
    plans = Rsk::Plans.new(test_pgsql, project)
    pid = plans.add(eid, 'solve it!')
    plans.get(pid, eid).schedule = (Time.now - (5 * 24 * 60 * 60)).strftime('%d-%m-%Y')
    pipeline = Rsk::Pipeline.new(test_pgsql, login)
    assert_equal(1, pipeline.fetch.count)
    assert(pipeline.fetch.any?(pid))
  end
end
