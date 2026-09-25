# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'
require_relative 'urror'

class Rsk::Limits
  def initialize(max: 10, period: 60)
    unless max.is_a?(Integer) && max.positive?
      raise(Rsk::Urror, "The maximum number of requests must be positive: #{max.inspect}")
    end
    unless period.is_a?(Integer) && period >= 0
      raise(Rsk::Urror, "The period must not be negative: #{period.inspect}")
    end
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
