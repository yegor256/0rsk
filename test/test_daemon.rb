# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../objects/daemon'
require_relative 'test__helper'

class Rsk::DaemonTest < Minitest::Test
  def test_starts_and_stops
    counter = 0
    Rsk::Daemon.new(0.01).start { counter += 1 }.tap { sleep(1.5) }.kill
    assert_operator(counter, :>=, 1)
  end
end
