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

class Rsk::TelepingsTest < Minitest::Test
  def test_add
    login = "judyT#{rand(99_999)}"
    project = Rsk::Projects.new(test_pgsql, login).add("test#{rand(99_999)}")
    chat = rand(99_999)
    Rsk::Telechats.new(test_pgsql).add(chat, login)
    cid = Rsk::Causes.new(test_pgsql, project).add('cause')
    rid = Rsk::Risks.new(test_pgsql, project).add('risk')
    eid = Rsk::Effects.new(test_pgsql, project).add('effect')
    triples = Rsk::Triples.new(test_pgsql, project)
    triples.add(cid, rid, eid)
    plans = Rsk::Plans.new(test_pgsql, project)
    pid = plans.add(eid, 'plan')
    plans.get(pid, eid).schedule = (Time.now - (60 * 60)).strftime('%d-%m-%Y')
    tasks = Rsk::Tasks.new(test_pgsql, login)
    tasks.create
    tid = tasks.fetch[0][:id]
    telepings = Rsk::Telepings.new(test_pgsql)
    telepings.add(tid, chat)
    telepings.add(tid, chat)
  end

  def test_required
    login = "judyR#{rand(99_999)}"
    telepings = Rsk::Telepings.new(test_pgsql)
    assert(telepings.required(login))
  end

  def test_required_after_add
    login = "judyRA#{rand(99_999)}"
    project = Rsk::Projects.new(test_pgsql, login).add("test#{rand(99_999)}")
    chat = rand(99_999)
    Rsk::Telechats.new(test_pgsql).add(chat, login)
    cid = Rsk::Causes.new(test_pgsql, project).add('cause')
    rid = Rsk::Risks.new(test_pgsql, project).add('risk')
    eid = Rsk::Effects.new(test_pgsql, project).add('effect')
    triples = Rsk::Triples.new(test_pgsql, project)
    triples.add(cid, rid, eid)
    plans = Rsk::Plans.new(test_pgsql, project)
    pid = plans.add(eid, 'plan')
    plans.get(pid, eid).schedule = (Time.now - (60 * 60)).strftime('%d-%m-%Y')
    tasks = Rsk::Tasks.new(test_pgsql, login)
    tasks.create
    telepings = Rsk::Telepings.new(test_pgsql)
    assert(telepings.required(login))
  end

  def test_fresh
    login = "judyF#{rand(99_999)}"
    project = Rsk::Projects.new(test_pgsql, login).add("test#{rand(99_999)}")
    Rsk::Telechats.new(test_pgsql).add(rand(99_999), login)
    cid = Rsk::Causes.new(test_pgsql, project).add('cause')
    rid = Rsk::Risks.new(test_pgsql, project).add('risk')
    eid = Rsk::Effects.new(test_pgsql, project).add('effect')
    triples = Rsk::Triples.new(test_pgsql, project)
    triples.add(cid, rid, eid)
    plans = Rsk::Plans.new(test_pgsql, project)
    pid = plans.add(eid, 'plan')
    plans.get(pid, eid).schedule = (Time.now - (60 * 60)).strftime('%d-%m-%Y')
    tasks = Rsk::Tasks.new(test_pgsql, login)
    tasks.create
    telepings = Rsk::Telepings.new(test_pgsql)
    refute_empty(telepings.fresh(login))
  end

  def test_fresh_after_ping
    login = "judyFA#{rand(99_999)}"
    project = Rsk::Projects.new(test_pgsql, login).add("test#{rand(99_999)}")
    chat = rand(99_999)
    Rsk::Telechats.new(test_pgsql).add(chat, login)
    cid = Rsk::Causes.new(test_pgsql, project).add('cause')
    rid = Rsk::Risks.new(test_pgsql, project).add('risk')
    eid = Rsk::Effects.new(test_pgsql, project).add('effect')
    triples = Rsk::Triples.new(test_pgsql, project)
    triples.add(cid, rid, eid)
    plans = Rsk::Plans.new(test_pgsql, project)
    pid = plans.add(eid, 'plan')
    plans.get(pid, eid).schedule = (Time.now - (60 * 60)).strftime('%d-%m-%Y')
    tasks = Rsk::Tasks.new(test_pgsql, login)
    tasks.create
    telepings = Rsk::Telepings.new(test_pgsql)
    tid = telepings.fresh(login)[0]
    telepings.add(tid, chat)
    assert_empty(telepings.fresh(login))
  end

  def test_fresh_tasks
    login = "judyFT#{rand(99_999)}"
    project = Rsk::Projects.new(test_pgsql, login).add("test#{rand(99_999)}")
    Rsk::Telechats.new(test_pgsql).add(rand(99_999), login)
    cid = Rsk::Causes.new(test_pgsql, project).add('cause')
    rid = Rsk::Risks.new(test_pgsql, project).add('risk')
    eid = Rsk::Effects.new(test_pgsql, project).add('effect')
    triples = Rsk::Triples.new(test_pgsql, project)
    triples.add(cid, rid, eid)
    plans = Rsk::Plans.new(test_pgsql, project)
    pid = plans.add(eid, 'plan')
    plans.get(pid, eid).schedule = (Time.now - (60 * 60)).strftime('%d-%m-%Y')
    tasks = Rsk::Tasks.new(test_pgsql, login)
    tasks.create
    telepings = Rsk::Telepings.new(test_pgsql)
    result = telepings.fresh_tasks(login, tasks)
    refute_empty(result)
    assert_kind_of(Integer, result[0][:rank])
  end
end
