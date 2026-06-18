# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../objects/projects'
require_relative '../objects/risks'
require_relative '../objects/rsk'

class Rsk::RisksTest < Minitest::Test
  def test_adds_and_fetches
    risks = Rsk::Risks.new(test_pgsql, Rsk::Projects.new(test_pgsql, 'jeff094').add('test09'))
    text = 'we may lose data'
    rid = risks.add(text)
    assert_predicate(rid, :positive?)
    assert_equal(1, risks.count)
    refute_empty(risks.fetch(query: 'Data'))
    assert(risks.fetch.any? { |r| r[:id] == rid })
    assert(risks.fetch.any? { |r| r[:text] == text })
  end
end
