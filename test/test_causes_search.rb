# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'securerandom'
require_relative 'test__helper'

require_relative '../objects/causes'

class Rsk::CausesSearchTest < TestCase
  def test_finds_a_text_that_carries_a_backslash
    causes = Rsk::Causes.new(test_pgsql, test_project)
    salt = SecureRandom.hex(8)
    causes.add("c:\\windows\\#{salt}")
    causes.add("one hundred % #{salt}")
    causes.add("snake_case #{salt}")
    assert_equal(1, causes.count(query: 'c:\\windows'), 'a backslash must be looked for as it is')
    assert_equal(1, causes.count(query: 'hundred %'), 'a percent sign must still be escaped')
    assert_equal(1, causes.count(query: 'snake_case'), 'an underscore must still be escaped')
  end
end
