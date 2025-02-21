# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'

# Users.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::Users
  def initialize(pgsql)
    @pgsql = pgsql
  end

  def fetch
    @pgsql.exec('SELECT login FROM project GROUP BY login').map { |r| r['login'] }
  end
end
