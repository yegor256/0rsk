# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require 'json'

# Test of Tasks.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2026 Yegor Bugayenko
# License:: MIT
class Rsk::TasksTest < Minitest::Test
  def test_adds_and_fetches
    login, pid = make_project(test_pgsql)
    cid = make_cause(test_pgsql, pid)
    rid = make_risk(test_pgsql, pid)
    rid2 = make_risk(test_pgsql, pid, text: 'we may lose it again')
    eid = make_effect(test_pgsql, pid)
    triples = Rsk::Triples.new(test_pgsql, pid)
    triples.add(cid, rid, eid)
    triples.add(cid, rid2, eid)
    plans = Rsk::Plans.new(test_pgsql, pid)
    plan_id = plans.add(eid, 'solve it!')
    plans.get(plan_id, eid).schedule = (Time.now - (5 * 24 * 60 * 60)).strftime('%d-%m-%Y')
    tasks = Rsk::Tasks.new(test_pgsql, login)
    tasks.create
    assert_equal(1, tasks.fetch.count)
    assert_equal(1, tasks.fetch(query: 'solve').count)
    assert_equal(1, tasks.fetch(query: 'business').count)
    assert_equal(1, tasks.fetch(query: 'data').count)
    assert_equal(1, tasks.fetch(query: 'again').count)
    assert_equal(1, tasks.count)
    assert(tasks.fetch.any? { |t| t[:plan] == plan_id })
  end

  def test_postpones_tasks
    t = make_task(test_pgsql)
    tasks = Rsk::Tasks.new(test_pgsql, t[:login])
    tasks.postpone(t[:task][:id], 60 * 60)
  end

  def test_tracks_task
    t = make_task(test_pgsql)
    tasks = Rsk::Tasks.new(test_pgsql, t[:login])
    tasks.track(t[:task][:id], 'owner/repo', 42)
    updated = tasks.fetch[0]
    refute_nil(updated[:tracker_data])
    td = JSON.parse(updated[:tracker_data])
    assert_equal('owner/repo', td['repo'])
    assert_equal(42, td['issue'])
  end
end
