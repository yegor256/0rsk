# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'

# Cause.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::Cause
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

  def emoji
    @pgsql.exec('SELECT emoji FROM cause WHERE id = $1', [@id])[0]['emoji']
  end

  def emoji=(char)
    raise Rsk::Urror, 'The emoji must be one-symbol only' if char.length > 1
    @pgsql.exec('UPDATE cause SET emoji = $2 WHERE id = $1', [@id, char])
  end
end
