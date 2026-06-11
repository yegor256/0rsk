# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

# Test of Pipeline.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2026 Yegor Bugayenko
# License:: MIT
class Rsk::PipelineTest < Minitest::Test
  def test_adds_and_fetches
    login, pid = make_project(test_pgsql)
    cid = make_cause(test_pgsql, pid)
    rid = make_risk(test_pgsql, pid)
    rid2 = make_risk(test_pgsql, pid, text: 'we may lose it again')
    eid = make_effect(test_pgsql, pid)
    triples = Rsk::Triples.new(test_pgsql, pid)
    triples.add(cid, rid, eid)
    triples.add(cid, rid2, eid)
    plan_id = make_plan(test_pgsql, pid, eid)
    pipeline = Rsk::Pipeline.new(test_pgsql, login)
    assert_equal(1, pipeline.fetch.count)
    assert(pipeline.fetch.any?(plan_id))
  end
end
