# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../objects/causes'
require_relative '../objects/projects'
require_relative '../objects/rsk'

class Rsk::CauseTest < Minitest::Test
  def test_modifies_text
    before = 'text first'
    after = 'another text to set'
    causes = Rsk::Causes.new(
      test_pgsql,
      Rsk::Projects.new(test_pgsql, "will#{rand(99_999)}").add("test#{rand(99_999)}")
    )
    cause = causes.get(causes.add(before))
    assert_equal(before, cause.text)
    cause.rename(after)
    assert_equal(after, cause.text)
  end

  def test_modifies_emoji
    causes = Rsk::Causes.new(
      test_pgsql,
      Rsk::Projects.new(test_pgsql, "bill#{rand(99_999)}").add("test#{rand(99_999)}")
    )
    cause = causes.get(causes.add('test me'))
    assert_equal('💾', cause.emoji)
    cause.decorate('📚')
    assert_equal('📚', cause.emoji)
  end

  def test_rejects_nil_emoji
    causes = Rsk::Causes.new(
      test_pgsql,
      Rsk::Projects.new(test_pgsql, "nill#{rand(99_999)}").add("test#{rand(99_999)}")
    )
    cause = causes.get(causes.add('test nil'))
    assert_raises(Rsk::Urror) { cause.decorate(nil) }
  end
end
