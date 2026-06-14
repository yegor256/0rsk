# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
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
require_relative '../objects/telechats'
require_relative '../objects/telepings'

# Test of Telepings.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2026 Yegor Bugayenko
# License:: MIT
class Rsk::TelepingsTest < Minitest::Test
  def test_fetches
    login = "judyT#{rand(99_999)}"
    test_tasks(login)
    telepings = Rsk::Telepings.new(pgsql)
    refute_empty(telepings.fresh(login))
    assert(telepings.required(login))
  end

  def test_adds
    login = "judyTA#{rand(99_999)}"
    tasks = test_tasks(login)
    telechats = Rsk::Telechats.new(pgsql)
    chat = rand(99_999)
    telechats.add(chat, login)
    telepings = Rsk::Telepings.new(pgsql)
    refute_empty(telepings.fresh(login))
    assert(telepings.required(login))
    tasks.fetch.each do |t|
      telepings.add(t[:id], chat)
      telepings.add(t[:id], chat)
    end
    assert_empty(telepings.fresh(login))
    refute(telepings.required(login))
  end

  # See https://github.com/yegor256/0rsk/issues/264
  def test_fresh_tasks_skips_orphan_ids
    login = "judyTO#{rand(99_999)}"
    project = Rsk::Projects.new(pgsql, login).add("test#{rand(9999)}")
    cid = Rsk::Causes.new(pgsql, project).add('orphan cause')
    plans = Rsk::Plans.new(pgsql, project)
    pid = plans.add(cid, 'orphan plan')
    plans.get(pid, cid).schedule = (Time.now - (5 * 24 * 60 * 60)).strftime('%d-%m-%Y')
    tid = pgsql.exec('INSERT INTO task (plan) VALUES ($1) RETURNING id', [pid])[0]['id'].to_i
    tasks = Rsk::Tasks.new(pgsql, login)
    telepings = Rsk::Telepings.new(pgsql)
    assert_includes(telepings.fresh(login), tid)
    assert_empty(tasks.fetch(query: tid))
    fresh = telepings.fresh_tasks(login, tasks)
    assert_kind_of(Array, fresh)
    assert(fresh.none?(&:nil?))
  end

  private

  def test_tasks(login)
    project = Rsk::Projects.new(pgsql, login).add("test#{rand(9999)}")
    cid = Rsk::Causes.new(pgsql, project).add('we have data')
    rid = Rsk::Risks.new(pgsql, project).add('we may lose it')
    eid = Rsk::Effects.new(pgsql, project).add('business will stop')
    triples = Rsk::Triples.new(pgsql, project)
    triples.add(cid, rid, eid)
    plans = Rsk::Plans.new(pgsql, project)
    pid = plans.add(rid, 'solve it!')
    plans.get(pid, rid).schedule = (Time.now - (5 * 24 * 60 * 60)).strftime('%d-%m-%Y')
    tasks = Rsk::Tasks.new(pgsql, login)
    tasks.create
    assert(tasks.fetch.any? { |t| t[:plan] == pid })
    tasks
  end
end
