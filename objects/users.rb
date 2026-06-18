# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'

class Rsk::Users
  def initialize(pgsql)
    @pgsql = pgsql
  end

  def fetch
    @pgsql.exec('SELECT login FROM project GROUP BY login').map { |r| r['login'] }
  end
end
