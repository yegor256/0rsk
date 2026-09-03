# frozen_string_literal: true

require_relative '../objects/postpone'
require_relative '../objects/urror'
# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

class Rsk::PostponeTest < Minitest::Test
  def test_resolves_week
    assert_equal(7 * 24 * 60 * 60, Rsk::Postpone.new('week').seconds)
  end

  def test_resolves_month
    assert_equal(30 * 24 * 60 * 60, Rsk::Postpone.new('month').seconds)
  end

  def test_resolves_quarter
    assert_equal(3 * 30 * 24 * 60 * 60, Rsk::Postpone.new('quarter').seconds)
  end

  def test_raises_on_unknown_period
    assert_raises(Rsk::Urror) { Rsk::Postpone.new('year').seconds }
  end

  def test_raises_on_missing_period
    assert_raises(Rsk::Urror) { Rsk::Postpone.new(nil).seconds }
  end
end
