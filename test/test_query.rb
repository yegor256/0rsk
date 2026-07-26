# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../objects/query'

class Rsk::QueryTest < Minitest::Test
  def test_fetch_pagination
    sql = ['SELECT * FROM project WHERE login = $1']
    query = Rsk::Query.new(test_pgsql, sql, ['test'])
    rows = query.fetch(0, 10)
    assert_kind_of(Array, rows)
  end

  def test_fetch_second_page
    sql = ['SELECT * FROM project WHERE login = $1']
    query = Rsk::Query.new(test_pgsql, sql, ['test'])
    rows = query.fetch(10, 10)
    assert_kind_of(Array, rows)
  end

  def test_count
    sql = ['SELECT 1 AS x']
    query = Rsk::Query.new(test_pgsql, sql, [])
    assert_equal(1, query.count)
  end

  def test_count_integer
    sql = ['SELECT generate_series(1, 5) AS x']
    query = Rsk::Query.new(test_pgsql, sql, [])
    assert_equal(5, query.count)
  end

  def test_empty_fetch
    sql = ['SELECT * FROM project WHERE login = $1']
    query = Rsk::Query.new(test_pgsql, sql, ['nonexistent_login'])
    rows = query.fetch(0, 0)
    assert_kind_of(Array, rows)
  end
end
