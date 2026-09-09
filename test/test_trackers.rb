# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../objects/trackers'

class Rsk::TrackersTest < TestCase
  def test_refuses_a_field_the_column_cannot_hold
    trackers = Rsk::Trackers.new(test_pgsql, test_project)
    bad = [[nil, 'x'], ['', 'x'], ['  ', 'x'], ['a/b', nil], ['a/b', ''], ['r' * 300, 'x']]
    bad.each do |repo, token|
      assert_raises(Rsk::Urror, "#{repo.inspect}/#{token.inspect} must be refused") do
        trackers.add(repo, token)
      end
    end
  end

  def test_adds_a_tracker
    trackers = Rsk::Trackers.new(test_pgsql, test_project)
    trackers.add('  foo/bar  ', 'tkn')
    assert_equal('foo/bar', trackers.fetch[0][:repo], 'the repository must be trimmed')
  end
end
