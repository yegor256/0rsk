# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'sentry-ruby'
require_relative 'rsk'

class Rsk::Daemon
  def initialize(minutes = 1)
    @minutes = minutes
  end

  def start
    Thread.start do
      loop do
        begin
          yield
        rescue Exception => e # rubocop:disable Lint/RescueException
          raise if e.is_a?(SystemExit) || e.is_a?(Interrupt) || e.is_a?(SignalException)
          Sentry.capture_exception(e)
        end
        sleep(@minutes * 60)
      end
    end
  end
end
