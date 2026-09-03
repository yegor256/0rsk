# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../objects/paging'
require_relative '../objects/urror'

class Rsk::PagingTest < TestCase
  def test_defaults
    paging = Rsk::Paging.new({}, limit: 25)
    assert_equal(0, paging.offset)
    assert_equal(25, paging.limit)
  end

  def test_clamps_the_limit
    assert_equal(1, Rsk::Paging.new({ limit: '-1' }).limit)
    assert_equal(1, Rsk::Paging.new({ limit: '0' }).limit)
    assert_equal(Rsk::Paging::MAX, Rsk::Paging.new({ limit: '99999999' }).limit)
    assert_equal(7, Rsk::Paging.new({ limit: '7' }).limit)
  end

  def test_clamps_the_offset
    assert_equal(0, Rsk::Paging.new({ offset: '-5' }).offset)
    assert_equal(5, Rsk::Paging.new({ offset: '5' }).offset)
  end

  def test_refuses_a_word
    assert_raises(Rsk::Urror) { Rsk::Paging.new({ offset: 'abc' }).offset }
    assert_raises(Rsk::Urror) { Rsk::Paging.new({ limit: 'abc' }).limit }
  end
end
