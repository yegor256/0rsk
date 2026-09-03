# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../objects/causes'
require_relative '../objects/projects'
require_relative '../objects/rsk'

class Rsk::CausesTest < TestCase
  def test_adds_and_fetches
    causes = Rsk::Causes.new(test_pgsql, test_project)
    text = 'we use Ruby'
    assert_equal(0, causes.count)
    cid = causes.add(text)
    assert_predicate(cid, :positive?)
    assert_equal(1, causes.count)
    assert(causes.fetch.any? { |c| c[:id] == cid })
    assert(causes.fetch.any? { |c| c[:text] == text })
  end

  def test_fetch_emojis
    causes = Rsk::Causes.new(test_pgsql, test_project)
    causes.get(causes.add('some cause')).decorate('💰')
    assert_operator(causes.emojis.count, :>, 1)
  end
end
