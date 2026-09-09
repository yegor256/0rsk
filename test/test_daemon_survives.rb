# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'timeout'
require_relative '../objects/daemon'
require_relative 'test__helper'

class Rsk::DaemonSurvivesTest < Minitest::Test
  def test_survives_an_error_outside_standard_error
    counter = 0
    d =
      Rsk::Daemon.new(0.001).start do
        counter += 1
        raise(NotImplementedError, 'this is not a StandardError') if counter == 1
      end
    begin
      sleep(0.5)
      assert_operator(counter, :>, 1)
      assert_predicate(d, :alive?)
    ensure
      d.kill
    end
  end

  def test_starts_without_delaying_the_caller
    Timeout.timeout(0.5) do
      assert_instance_of(Thread, Rsk::Daemon.new(0.001).start { nil }.tap(&:kill))
    end
  end
end
