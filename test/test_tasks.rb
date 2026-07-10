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

class Rsk::TasksTest < TestCase
  def test_adds_and_fetches
    login = "bobbyT#{rand(99_999)}"
    project = Rsk::Projects.new(test_pgsql, login).add("test#{rand(99_999)}")
    cid = Rsk::Causes.new(test_pgsql, project).add('we have data')
    eid = Rsk::Effects.new(test_pgsql, project).add('business will stop')
    triples = Rsk::Triples.new(test_pgsql, project)
    triples.add(cid, Rsk::Risks.new(test_pgsql, project).add('we may lose it'), eid)
    triples.add(cid, Rsk::Risks.new(test_pgsql, project).add('we may lose it again'), eid)
    plans = Rsk::Plans.new(test_pgsql, project)
    pid = plans.add(eid, 'solve it!')
    plans.get(pid, eid).reschedule((Time.now - (5 * 24 * 60 * 60)).strftime('%d-%m-%Y'))
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
    eid = Rsk::Effects.new(test_pgsql, project).add('business will stop')
    Rsk::Triples.new(test_pgsql, project).add(
      Rsk::Causes.new(test_pgsql, project).add('we have data'),
      Rsk::Risks.new(test_pgsql, project).add('we may lose it'), eid
    )
    plans = Rsk::Plans.new(test_pgsql, project)
    plans.get(plans.add(eid, 'solve it!'), eid).reschedule((Time.now - (5 * 24 * 60 * 60)).strftime('%d-%m-%Y'))
    tasks = Rsk::Tasks.new(test_pgsql, login)
    tasks.create
    tasks.postpone(tasks.fetch[0][:id], 60 * 60)
  end

  def test_postpones_using_transaction_connection
    queries = []
    transaction = Object.new
    transaction.define_singleton_method(:exec) do |query, _params|
      queries << query
      query.start_with?('SELECT schedule') ? [{ 'schedule' => '01-01-2026' }] : []
    end
    calls = 0
    active = false
    pgsql = Object.new
    pgsql.define_singleton_method(:exec) do |query, _params|
      raise(RuntimeError, 'Pool connection checked out inside transaction') if active
      calls += 1
      Array(query).join.include?('SELECT project.*') ? [{ 'login' => 'tester' }] :
        [{ 'project' => '1', 'id' => '2', 'part' => '3' }]
    end
    pgsql.define_singleton_method(:transaction) do |&block|
      active = true
      block.call(transaction)
    ensure
      active = false
    end
    Rsk::Tasks.new(pgsql, 'tester').postpone(4, 60)
    assert_equal(2, calls)
    assert_equal(3, queries.size)
  end
end
