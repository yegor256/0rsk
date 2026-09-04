# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'
require_relative 'urror'

class Rsk::Risk
  attr_reader :id

  def initialize(pgsql, id)
    @pgsql = pgsql
    @id = id
  end

  def text
    @pgsql.exec('SELECT text FROM part WHERE id = $1', [@id])[0]['text']
  end

  def rename(text)
    @pgsql.exec('UPDATE part SET text = $2 WHERE id = $1', [@id, text])
  end

  def probability
    Integer(@pgsql.exec('SELECT probability FROM risk WHERE id = $1', [@id])[0]['probability'])
  end

  def weigh(value)
    unless (1..9).cover?(value)
      raise(Rsk::Urror, "The probability must be between 1 and 9: #{value.inspect}")
    end
    @pgsql.exec('UPDATE risk SET probability = $2 WHERE id = $1', [@id, value])
  end
end
