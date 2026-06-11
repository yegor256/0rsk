# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

class Rsk::CausesTest < Minitest::Test
  def test_adds_and_fetches
    _login, pid = make_project(test_pgsql)
    causes = Rsk::Causes.new(test_pgsql, pid)
    text = 'we use Ruby'
    assert_equal(0, causes.count)
    cid = causes.add(text)
    assert_predicate(cid, :positive?)
    assert_equal(1, causes.count)
    assert(causes.fetch.any? { |c| c[:id] == cid })
    assert(causes.fetch.any? { |c| c[:text] == text })
  end

  def test_fetch_emojis
    _login, pid = make_project(test_pgsql)
    causes = Rsk::Causes.new(test_pgsql, pid)
    cid = causes.add('some cause')
    causes.get(cid).emoji = "\u{1F4B0}"
    assert_operator(causes.emojis.count, :>, 1)
  end
end
