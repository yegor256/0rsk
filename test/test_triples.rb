# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

# Test of Triples.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2026 Yegor Bugayenko
# License:: MIT
class Rsk::TriplesTest < Minitest::Test
  def test_adds_and_fetches
    _login, pid = make_project(test_pgsql)
    cid = make_cause(test_pgsql, pid)
    rid = make_risk(test_pgsql, pid)
    eid = make_effect(test_pgsql, pid)
    triples = Rsk::Triples.new(test_pgsql, pid)
    assert_equal(0, triples.count)
    tid = triples.add(cid, rid, eid)
    triples.add(cid, rid, eid)
    assert_equal(1, triples.count)
    assert(triples.fetch.any? { |t| t[:id] == tid })
    assert_equal(0, triples.fetch(id: tid)[0][:plans].count)
    triples.fetch.each { |t| triples.delete(t[:id]) }
  end

  def test_fetches_with_plans
    _login, pid = make_project(test_pgsql)
    t = make_triple(test_pgsql, pid, effect: 'business will stop NOW')
    triples = Rsk::Triples.new(test_pgsql, pid)
    assert_equal(1, triples.fetch(query: '+alone').count)
    assert_equal(1, triples.fetch(query: "+#{t[:cause]}").count)
    assert_equal(1, triples.fetch(query: "+#{t[:risk]}").count)
    assert_equal(1, triples.fetch(query: "+#{t[:effect]}").count)
    plans = Rsk::Plans.new(test_pgsql, pid)
    plans.add(t[:risk], 'we\'ll do "it"')
    plans.add(t[:effect], 'and this "one" too SUPER')
    assert_equal(2, triples.fetch(id: t[:triple])[0][:plans].count)
    assert_equal(1, triples.fetch(query: 'super').count)
    assert_equal(1, triples.fetch(query: 'now').count)
    assert_equal(0, triples.fetch(query: 'something-else').count)
    assert_equal(1, triples.fetch.count)
  end
end
