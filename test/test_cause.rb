# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../objects/rsk'
require_relative '../objects/causes'
require_relative '../objects/projects'

# Test of Cause.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::CauseTest < Minitest::Test
  def test_modifies_text
    pid = Rsk::Projects.new(test_pgsql, "will#{rand(99_999)}").add("test#{rand(99_999)}")
    before = 'text first'
    after = 'another text to set'
    causes = Rsk::Causes.new(test_pgsql, pid)
    cause = causes.get(causes.add(before))
    assert_equal(before, cause.text)
    cause.text = after
    assert_equal(after, cause.text)
  end

  def test_modifies_emoji
    pid = Rsk::Projects.new(test_pgsql, "bill#{rand(99_999)}").add("test#{rand(99_999)}")
    causes = Rsk::Causes.new(test_pgsql, pid)
    cause = causes.get(causes.add('test me'))
    assert_equal('💾', cause.emoji)
    cause.emoji = '📚'
    assert_equal('📚', cause.emoji)
  end
end
