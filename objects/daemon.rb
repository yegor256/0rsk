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
    sleep(1)
    Thread.start do
      loop do
        begin
          yield
        rescue StandardError => e
          Sentry.capture_exception(e)
        end
        sleep(@minutes * 60)
      end
    end
  end
end
