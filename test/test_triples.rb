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
require_relative '../objects/triples'

class Rsk::TriplesTest < TestCase
  def test_adds_and_fetches
    project = test_project
    cid = test_cause(project: project)
    rid = test_risk(project: project)
    eid = test_effect(project: project)
    triples = Rsk::Triples.new(test_pgsql, project)
    assert_equal(0, triples.count)
    tid = triples.add(cid, rid, eid)
    triples.add(cid, rid, eid)
    assert_equal(1, triples.count)
    assert(triples.fetch.any? { |t| t[:id] == tid })
    assert_equal(0, triples.fetch(id: tid)[0][:plans].count)
    triples.fetch.each { |t| triples.delete(t[:id]) }
  end

  def test_fetches_a_plan_whose_text_has_a_newline
    project = test_project
    eid = test_effect(project: project)
    triples = Rsk::Triples.new(test_pgsql, project)
    triples.add(test_cause(project: project), test_risk(project: project), eid)
    Rsk::Plans.new(test_pgsql, project).add(eid, "pay the bill\nand check it")
    assert_equal(1, triples.fetch[0][:plans].count)
    assert_includes(triples.fetch[0][:plans][0][:text], "pay the bill\nand check it")
  end

  def test_deletes_with_one_connection
    pgsql = Pgtk::Pool.new(
      Pgtk::Wire::Yaml.new(File.join(__dir__, '../target/pgsql-config.yml')),
      max: 1,
      timeout: 0.1,
      log: Loog::NULL
    )
    pgsql.start!
    project = Rsk::Projects.new(pgsql, "bobbyT#{SecureRandom.hex(8)}").add("test#{SecureRandom.hex(8)}")
    triples = Rsk::Triples.new(pgsql, project)
    triples.delete(
      triples.add(
        Rsk::Causes.new(pgsql, project).add('we have data'),
        Rsk::Risks.new(pgsql, project).add('we may lose it'),
        Rsk::Effects.new(pgsql, project).add('business will stop')
      )
    )
    assert_equal(0, triples.count)
  end

  def test_rejects_cross_project_parts
    project = test_project
    rid = test_risk(project: project)
    eid = test_effect(project: project)
    other = test_cause
    triples = Rsk::Triples.new(test_pgsql, project)
    assert_raises(Rsk::Urror) { triples.add(other, rid, eid) }
  end

  def test_fetches_with_plans
    project = test_project
    cid = Rsk::Causes.new(test_pgsql, project).add('we have data')
    rid = Rsk::Risks.new(test_pgsql, project).add('we may lose it')
    eid = Rsk::Effects.new(test_pgsql, project).add('business will stop NOW')
    triples = Rsk::Triples.new(test_pgsql, project)
    triples.add(cid, rid, eid)
    assert_equal(1, triples.fetch(query: '+alone').count)
    assert_equal(1, triples.fetch(query: "+#{cid}").count)
    assert_equal(1, triples.fetch(query: "+#{rid}").count)
    assert_equal(1, triples.fetch(query: "+#{eid}").count)
    plans = Rsk::Plans.new(test_pgsql, project)
    plans.add(rid, 'we\'ll do "it"')
    plans.add(eid, 'and this "one" too SUPER')
    assert_equal(2, triples.fetch(query: "+#{cid}")[0][:plans].count)
    assert_equal(1, triples.fetch(query: 'super').count)
    assert_equal(1, triples.fetch(query: 'now').count)
    assert_equal(0, triples.fetch(query: 'something-else').count)
    assert_equal(1, triples.fetch.count)
  end
end
