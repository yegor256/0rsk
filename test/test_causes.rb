# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../objects/rsk'
require_relative '../objects/causes'
require_relative '../objects/projects'

# Test of Causes.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2026 Yegor Bugayenko
# License:: MIT
class Rsk::CausesTest < Minitest::Test
  def test_adds_and_fetches
    pid = Rsk::Projects.new(test_pgsql, "timm#{rand(99_999)}").add("t#{rand(99_999)}")
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
    pid = Rsk::Projects.new(test_pgsql, "tim#{rand(99_999)}").add("t#{rand(99_999)}")
    causes = Rsk::Causes.new(test_pgsql, pid)
    cid = causes.add('some cause')
    causes.get(cid).emoji = '💰'
    assert_operator(causes.emojis.count, :>, 1)
  end

  def test_rejects_cause_from_another_project
    mine = Rsk::Projects.new(test_pgsql, "my#{rand(99_999)}").add("t#{rand(99_999)}")
    other = Rsk::Projects.new(test_pgsql, "you#{rand(99_999)}").add("t#{rand(99_999)}")
    cid = Rsk::Causes.new(test_pgsql, other).add('other cause')
    assert_raises(Rsk::Urror) { Rsk::Causes.new(test_pgsql, mine).get(cid) }
  end
end
