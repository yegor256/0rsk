# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

class Rsk::RiskTest < Minitest::Test
  def test_modifies_text
    _login, pid = make_project(test_pgsql)
    before = 'text first'
    after = 'another text to set'
    risks = Rsk::Risks.new(test_pgsql, pid)
    risk = risks.get(risks.add(before))
    assert_equal(before, risk.text)
    risk.text = after
    assert_equal(after, risk.text)
  end

  def test_modifies_probability
    _login, pid = make_project(test_pgsql)
    after = 9
    risks = Rsk::Risks.new(test_pgsql, pid)
    risk = risks.get(risks.add('some risk'))
    risk.probability = after
    assert_equal(after, risk.probability)
  end
end
