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
require_relative '../objects/plans'

# Test of Triples.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::TriplesTest < Minitest::Test
  def test_adds_and_fetches
    login = "sarah#{rand(99_999)}"
    project = Rsk::Projects.new(test_pgsql, login).add("test#{rand(99_999)}")
    cid = Rsk::Causes.new(test_pgsql, project).add('we have data')
    rid = Rsk::Risks.new(test_pgsql, project).add('we may lose it')
    eid = Rsk::Effects.new(test_pgsql, project).add('business will stop')
    triples = Rsk::Triples.new(test_pgsql, project)
    assert_equal(0, triples.count)
    tid = triples.add(cid, rid, eid)
    triples.add(cid, rid, eid)
    assert_equal(1, triples.count)
    assert(triples.fetch.any? { |t| t[:id] == tid })
    assert_equal(0, triples.fetch(id: tid)[0][:plans].count)
    triples.fetch.each { |t| triples.delete(t[:id]) }
  end

  def test_fetches_with_plans
    login = "sarahP#{rand(99_999)}"
    project = Rsk::Projects.new(test_pgsql, login).add("test#{rand(99_999)}")
    cid = Rsk::Causes.new(test_pgsql, project).add('we have data')
    rid = Rsk::Risks.new(test_pgsql, project).add('we may lose it')
    eid = Rsk::Effects.new(test_pgsql, project).add('business will stop NOW')
    triples = Rsk::Triples.new(test_pgsql, project)
    tid = triples.add(cid, rid, eid)
    assert_equal(1, triples.fetch(query: '+alone').count)
    assert_equal(1, triples.fetch(query: "+#{cid}").count)
    assert_equal(1, triples.fetch(query: "+#{rid}").count)
    assert_equal(1, triples.fetch(query: "+#{eid}").count)
    plans = Rsk::Plans.new(test_pgsql, project)
    plans.add(rid, 'we\'ll do "it"')
    plans.add(eid, 'and this "one" too SUPER')
    assert_equal(2, triples.fetch(id: tid)[0][:plans].count)
    assert_equal(1, triples.fetch(query: 'super').count)
    assert_equal(1, triples.fetch(query: 'now').count)
    assert_equal(0, triples.fetch(query: 'something-else').count)
    assert_equal(1, triples.fetch.count)
  end
end
