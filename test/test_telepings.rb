# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require 'securerandom'
require_relative '../objects/causes'
require_relative '../objects/effects'
require_relative '../objects/plans'
require_relative '../objects/projects'
require_relative '../objects/risks'
require_relative '../objects/rsk'
require_relative '../objects/tasks'
require_relative '../objects/telechats'
require_relative '../objects/telepings'
require_relative '../objects/triples'

class Rsk::TelepingsTest < TestCase
  def test_fetches
    login = "judyT#{rand(99_999)}"
    test_tasks(login)
    telepings = Rsk::Telepings.new(test_pgsql)
    refute_empty(telepings.fresh(login))
    assert(telepings.required?(login))
  end

  def test_adds
    login = "judyTA#{rand(99_999)}"
    tasks = test_tasks(login)
    chat = SecureRandom.random_number(2_000_000_000) + 1
    Rsk::Telechats.new(test_pgsql).add(chat, login)
    telepings = Rsk::Telepings.new(test_pgsql)
    refute_empty(telepings.fresh(login))
    assert(telepings.required?(login))
    tasks.fetch.each do |t|
      telepings.add(t[:id], chat)
      telepings.add(t[:id], chat)
    end
    assert_empty(telepings.fresh(login))
    refute(telepings.required?(login))
  end

  def test_fresh_tasks_skips_orphan_ids
    login = "judyTO#{rand(99_999)}"
    project = Rsk::Projects.new(test_pgsql, login).add("test#{rand(9999)}")
    cid = Rsk::Causes.new(test_pgsql, project).add('orphan cause')
    plans = Rsk::Plans.new(test_pgsql, project)
    pid = plans.add(cid, 'orphan plan')
    plans.get(pid, cid).reschedule((Time.now - (5 * 24 * 60 * 60)).strftime('%d-%m-%Y'))
    tid = Integer(test_pgsql.exec('INSERT INTO task (plan) VALUES ($1) RETURNING id', [pid])[0]['id'])
    tasks = Rsk::Tasks.new(test_pgsql, login)
    telepings = Rsk::Telepings.new(test_pgsql)
    assert_includes(telepings.fresh(login), tid)
    assert_empty(tasks.fetch(query: tid))
    fresh = telepings.pending(login, tasks)
    assert_kind_of(Array, fresh)
    assert(fresh.none?(&:nil?))
  end

  private

  def test_tasks(login)
    project = Rsk::Projects.new(test_pgsql, login).add("test#{rand(9999)}")
    rid = Rsk::Risks.new(test_pgsql, project).add('we may lose it')
    Rsk::Triples.new(test_pgsql, project).add(
      Rsk::Causes.new(test_pgsql, project).add('we have data'), rid,
      Rsk::Effects.new(test_pgsql, project).add('business will stop')
    )
    plans = Rsk::Plans.new(test_pgsql, project)
    pid = plans.add(rid, 'solve it!')
    plans.get(pid, rid).reschedule((Time.now - (5 * 24 * 60 * 60)).strftime('%d-%m-%Y'))
    tasks = Rsk::Tasks.new(test_pgsql, login)
    tasks.create
    assert(tasks.fetch.any? { |t| t[:plan] == pid })
    tasks
  end
end
