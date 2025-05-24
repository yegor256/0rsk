# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'sentry-ruby'
require_relative 'rsk'

# Daemon.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
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
