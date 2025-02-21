# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'rack/test'
require_relative 'test__helper'
require_relative '../objects/rsk'
require_relative '../objects/plans'
require_relative '../objects/projects'
require_relative '../objects/risks'

# Test of Plans.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::PlansTest < Minitest::Test
  def test_adds_and_fetches
    pid = Rsk::Projects.new(test_pgsql, 'jeff23').add("test#{rand(99_999)}")
    risks = Rsk::Risks.new(test_pgsql, pid)
    rid = risks.add('we may lose data')
    plans = Rsk::Plans.new(test_pgsql, pid)
    text = 'we make backups'
    id = plans.add(rid, text)
    plans.get(id, rid).schedule = '01-01-2001'
    assert(id.positive?)
    assert_equal(1, plans.count)
    assert(!plans.fetch.empty?)
    assert(plans.fetch.any? { |p| p[:text] == text })
    plans.get(id, rid).complete
  end
end
