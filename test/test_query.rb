# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../objects/query'
require_relative 'test__helper'

class Rsk::QueryTest < TestCase
  def test_fetch_pagination
    assert_kind_of(
      Array,
      Rsk::Query.new(test_pgsql, ['SELECT * FROM project WHERE login = $1'], ['test']).fetch(0, 10)
    )
  end

  def test_fetch_second_page
    assert_kind_of(
      Array,
      Rsk::Query.new(test_pgsql, ['SELECT * FROM project WHERE login = $1'], ['test']).fetch(10, 10)
    )
  end

  def test_count
    assert_equal(1, Rsk::Query.new(test_pgsql, ['SELECT 1 AS x'], []).count)
  end

  def test_count_integer
    assert_equal(5, Rsk::Query.new(test_pgsql, ['SELECT generate_series(1, 5) AS x'], []).count)
  end

  def test_empty_fetch
    assert_kind_of(
      Array,
      Rsk::Query.new(
        test_pgsql, ['SELECT * FROM project WHERE login = $1'], ['nonexistent_login']
      ).fetch(0, 0)
    )
  end
end
