# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

class Rsk::TrackersTest < Minitest::Test
  def test_adds_and_fetches
    _login, pid = make_project(test_pgsql)
    trackers = Rsk::Trackers.new(test_pgsql, pid)
    assert_equal(0, trackers.fetch.count)
    id = trackers.add('owner/repo', 'secret_token')
    assert_predicate(id, :positive?)
    rows = trackers.fetch
    assert_equal(1, rows.count)
    assert(rows.any? { |t| t[:id] == id })
    assert(rows.any? { |t| t[:repo] == 'owner/repo' })
    assert(rows.any? { |t| t[:type] == 'github' })
    assert(rows.any? { |t| t[:token] == 'secret_token' })
    assert(rows.any? { |t| t[:created].is_a?(Time) })
  end

  def test_deletes
    _login, pid = make_project(test_pgsql)
    trackers = Rsk::Trackers.new(test_pgsql, pid)
    id = trackers.add('owner/repo', 'tok')
    assert(trackers.exists?(id))
    trackers.delete(id)
    refute(trackers.exists?(id))
    assert_empty(trackers.fetch)
  end

  def test_exists_returns_false_for_wrong_project
    _login, pid1 = make_project(test_pgsql)
    _login, pid2 = make_project(test_pgsql)
    t1 = Rsk::Trackers.new(test_pgsql, pid1)
    id = t1.add('owner/repo', 'tok')
    t2 = Rsk::Trackers.new(test_pgsql, pid2)
    refute(t2.exists?(id))
  end
end
