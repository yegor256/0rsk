# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'

class Rsk::Project
  def initialize(pgsql, id)
    @pgsql = pgsql
    @id = id
  end

  def login
    @pgsql.exec('SELECT login FROM project WHERE id = $1', [@id])[0]['login']
  end
end
