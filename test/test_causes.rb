# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../objects/causes'
require_relative '../objects/projects'
require_relative '../objects/rsk'

class Rsk::CausesTest < Minitest::Test
  def test_adds_and_fetches
    causes = Rsk::Causes.new(test_pgsql, Rsk::Projects.new(test_pgsql, "timm#{rand(99_999)}").add("t#{rand(99_999)}"))
    text = 'we use Ruby'
    assert_equal(0, causes.count)
    cid = causes.add(text)
    assert_predicate(cid, :positive?)
    assert_equal(1, causes.count)
    assert(causes.fetch.any? { |c| c[:id] == cid })
    assert(causes.fetch.any? { |c| c[:text] == text })
  end

  def test_fetch_emojis
    causes = Rsk::Causes.new(test_pgsql, Rsk::Projects.new(test_pgsql, "tim#{rand(99_999)}").add("t#{rand(99_999)}"))
    causes.get(causes.add('some cause')).decorate('💰')
    assert_operator(causes.emojis.count, :>, 1)
  end
end
