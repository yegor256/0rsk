# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'

class Rsk::Limits
  def initialize(max: 10, period: 60)
    @max = max
    @period = period
    @seen = {}
    @mutex = Mutex.new
  end

  def over?(client, now: Time.now.to_i)
    @mutex.synchronize do
      @seen.each_value { |hits| hits.reject! { |t| t < now - @period } }
      @seen.reject! { |_, hits| hits.empty? }
      hits = (@seen[client] ||= [])
      hits << now
      hits.size > @max
    end
  end
end
