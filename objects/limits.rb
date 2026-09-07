# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'

class Rsk::Limits
  SWEEP = 1024

  def initialize(max: 10, period: 60)
    @max = max
    @period = period
    @seen = {}
    @mutex = Mutex.new
  end

  def over?(client, now: Time.now.to_i)
    @mutex.synchronize do
      sweep(now) if @seen.size > Rsk::Limits::SWEEP
      hits = (@seen[client] ||= [])
      hits.reject! { |t| t < now - @period }
      over = hits.size >= @max
      hits << now unless over
      over
    end
  end

  private

  def sweep(now)
    @seen.each_value { |hits| hits.reject! { |t| t < now - @period } }
    @seen.reject! { |_, hits| hits.empty? }
  end
end
