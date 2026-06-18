# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../objects/projects'
require_relative '../objects/risks'
require_relative '../objects/rsk'

class Rsk::RiskTest < Minitest::Test
  def test_modifies_text
    before = 'text first'
    after = 'another text to set'
    risks = Rsk::Risks.new(test_pgsql, Rsk::Projects.new(test_pgsql, 'jeff32').add('test'))
    risk = risks.get(risks.add(before))
    assert_equal(before, risk.text)
    risk.rename(after)
    risk.rename(after)
    assert_equal(after, risk.text)
  end

  def test_modifies_probability
    after = 9
    risks = Rsk::Risks.new(test_pgsql, Rsk::Projects.new(test_pgsql, 'jeff94').add('test'))
    risk = risks.get(risks.add('some risk'))
    risk.weigh(after)
    risk.weigh(after)
    assert_equal(after, risk.probability)
  end
end
