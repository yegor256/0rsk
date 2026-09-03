# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'
require_relative 'urror'

class Rsk::Paging
  MAX = 100

  def initialize(params, limit: 10)
    @params = params
    @limit = limit
  end

  def offset
    [number(:offset, 0), 0].max
  end

  def limit
    number(:limit, @limit).clamp(1, Rsk::Paging::MAX)
  end

  private

  def number(name, default)
    text = @params[name]
    return default if text.nil? || text.to_s.empty?
    begin
      Integer(text.to_s, 10)
    rescue ArgumentError
      raise(Rsk::Urror, "The #{name} must be a number: #{text.inspect}")
    end
  end
end
