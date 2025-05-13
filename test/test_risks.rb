# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'rack/test'
require_relative 'test__helper'
require_relative '../objects/rsk'
require_relative '../objects/risks'
require_relative '../objects/projects'

# Test of Risks.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::RisksTest < Minitest::Test
  def test_adds_and_fetches
    pid = Rsk::Projects.new(test_pgsql, 'jeff094').add('test09')
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
