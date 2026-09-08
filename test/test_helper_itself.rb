# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

class Rsk::HelperTest < TestCase
  def test_counts_only_the_real_tests
    assert_equal(
      ['test_counts_only_the_real_tests'],
      Rsk::HelperTest.runnable_methods.sort,
      'the pool helper must not be run as a test'
    )
  end
end
