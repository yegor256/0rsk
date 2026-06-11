# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

class Rsk::CauseTest < Minitest::Test
  def test_modifies_text
    _login, pid = make_project(test_pgsql)
    before = 'text first'
    after = 'another text to set'
    causes = Rsk::Causes.new(test_pgsql, pid)
    cause = causes.get(causes.add(before))
    assert_equal(before, cause.text)
    cause.text = after
    assert_equal(after, cause.text)
  end

  def test_modifies_emoji
    _login, pid = make_project(test_pgsql)
    causes = Rsk::Causes.new(test_pgsql, pid)
    cause = causes.get(causes.add('test me'))
    assert_equal("\u{1F4BE}", cause.emoji)
    cause.emoji = "\u{1F4DA}"
    assert_equal("\u{1F4DA}", cause.emoji)
  end
end
