# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'

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
    @pgsql.exec('UPDATE risk SET probability = $2 WHERE id = $1', [@id, value])
  end
end
