# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../objects/rsk'
require_relative '../objects/causes'
require_relative '../objects/risks'
require_relative '../objects/effects'
require_relative '../objects/projects'
require_relative '../objects/triples'
require_relative '../objects/tasks'
require_relative '../objects/plans'

# Test of Tasks.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::TasksTest < Minitest::Test
  def test_adds_and_fetches
    login = "bobbyT#{rand(99_999)}"
    project = Rsk::Projects.new(test_pgsql, login).add("test#{rand(99_999)}")
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
    tasks = Rsk::Tasks.new(test_pgsql, login)
    tasks.create
    assert_equal(1, tasks.fetch.count)
    assert_equal(1, tasks.fetch(query: 'solve').count)
    assert_equal(1, tasks.fetch(query: 'business').count)
    assert_equal(1, tasks.fetch(query: 'data').count)
    assert_equal(1, tasks.fetch(query: 'again').count)
    assert_equal(1, tasks.count)
    assert(tasks.fetch.any? { |t| t[:plan] == pid })
  end

  def test_postpones_tasks
    login = "bobbyX#{rand(99_999)}"
    project = Rsk::Projects.new(test_pgsql, login).add("test#{rand(99_999)}")
    cid = Rsk::Causes.new(test_pgsql, project).add('we have data')
    rid = Rsk::Risks.new(test_pgsql, project).add('we may lose it')
    eid = Rsk::Effects.new(test_pgsql, project).add('business will stop')
    triples = Rsk::Triples.new(test_pgsql, project)
    triples.add(cid, rid, eid)
    plans = Rsk::Plans.new(test_pgsql, project)
    pid = plans.add(eid, 'solve it!')
    plans.get(pid, eid).schedule = (Time.now - (5 * 24 * 60 * 60)).strftime('%d-%m-%Y')
    tasks = Rsk::Tasks.new(test_pgsql, login)
    tasks.create
    task = tasks.fetch[0]
    tasks.postpone(task[:id], 60 * 60)
  end
end
