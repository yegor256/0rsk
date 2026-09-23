# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../objects/rsk'
require_relative '../objects/trackers'

class Rsk::TrackersTest < TestCase
  def test_stores_given_type
    trackers = Rsk::Trackers.new(test_pgsql, test_project)
    trackers.add('gitlab', "foo/#{SecureRandom.hex(8)}", 'secret')
    assert_equal('gitlab', trackers.fetch.first[:type])
  end
end
