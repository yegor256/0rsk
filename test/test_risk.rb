# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../objects/rsk'
require_relative '../objects/risks'
require_relative '../objects/projects'

# Test of Risk.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::RiskTest < Minitest::Test
  def test_modifies_text
    pid = Rsk::Projects.new(test_pgsql, 'jeff32').add('test')
    before = 'text first'
    after = 'another text to set'
    risks = Rsk::Risks.new(test_pgsql, pid)
    risk = risks.get(risks.add(before))
    assert_equal(before, risk.text)
    risk.text = after
    risk.text = after
    assert_equal(after, risk.text)
  end

  def test_modifies_probability
    pid = Rsk::Projects.new(test_pgsql, 'jeff94').add('test')
    after = 9
    risks = Rsk::Risks.new(test_pgsql, pid)
    risk = risks.get(risks.add('some risk'))
    risk.probability = after
    risk.probability = after
    assert_equal(after, risk.probability)
  end
end
