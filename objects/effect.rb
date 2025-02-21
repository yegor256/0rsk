# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'

# Effect.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::Effect
  attr_reader :id

  def initialize(pgsql, id)
    @pgsql = pgsql
    @id = id
  end

  def text
    @pgsql.exec('SELECT text FROM part WHERE id = $1', [@id])[0]['text']
  end

  def text=(text)
    @pgsql.exec('UPDATE part SET text = $2 WHERE id = $1', [@id, text])
  end

  def impact
    @pgsql.exec('SELECT impact FROM effect WHERE id = $1', [@id])[0]['impact'].to_i
  end

  def impact=(value)
    @pgsql.exec(
      'UPDATE effect SET impact = $2 WHERE id = $1',
      [@id, value]
    )
  end

  def positive?
    @pgsql.exec('SELECT positive FROM effect WHERE id = $1', [@id])[0]['positive'] == 't'
  end

  def positive=(v)
    @pgsql.exec('UPDATE effect SET positive = $2 WHERE id = $1', [@id, v])
  end
end
