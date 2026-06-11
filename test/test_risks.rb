# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

class Rsk::RisksTest < Minitest::Test
  def test_adds_and_fetches
    _login, pid = make_project(test_pgsql)
    risks = Rsk::Risks.new(test_pgsql, pid)
    text = 'we may lose data'
    rid = risks.add(text)
    assert_predicate(rid, :positive?)
    assert_equal(1, risks.count)
    refute_empty(risks.fetch(query: 'Data'))
    assert(risks.fetch.any? { |r| r[:id] == rid })
    assert(risks.fetch.any? { |r| r[:text] == text })
  end
end
