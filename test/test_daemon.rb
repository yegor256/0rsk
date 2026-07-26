# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../objects/daemon'

class Rsk::DaemonTest < Minitest::Test
  def test_starts_and_stops
    counter = 0
    daemon = Rsk::Daemon.new(0.01)
    thread = daemon.start { counter += 1 }
    sleep 1.5
    thread.kill
    assert_operator counter, :>=, 1
  end
end
