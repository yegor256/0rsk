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

  def test_postpones_without_reusing_outer_pool_in_transaction
    pgsql = Class.new do
      attr_reader :updated

      def initialize
        @in_transaction = false
      end

      def exec(sql, args)
        return exec_in_transaction(sql, args) if @in_transaction
        outer_exec(sql)
      end

      def transaction
        @in_transaction = true
        yield(self)
      ensure
        @in_transaction = false
      end

      def exec_in_transaction(sql, args)
        case sql
        when /DELETE FROM task WHERE id = \$1/
          nil
        when /SELECT schedule FROM plan WHERE id = \$1 AND part = \$2/
          [{ 'schedule' => '01-01-2001' }]
        when /UPDATE plan SET schedule = \$3 WHERE id = \$1 AND part = \$2/
          @updated = args
          nil
        else
          raise "Unexpected transaction SQL: #{sql}"
        end
      end

      def outer_exec(sql)
        case sql
        when /SELECT project\.\* FROM project/
          [{ 'login' => 'jeff' }]
        when /SELECT plan\.\* FROM plan JOIN task/
          [{ 'id' => '7', 'part' => '11', 'project' => '13' }]
        else
          raise "Unexpected outer SQL: #{sql}"
        end
      end
    end.new
    tasks = Rsk::Tasks.new(pgsql, 'jeff')
    tasks.postpone(5, 0)
    assert_equal(['7', '11'], pgsql.updated[0..1])
    assert_match(/^\d{2}-\d{2}-\d{4}$/, pgsql.updated[2])
  end
end
