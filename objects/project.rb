# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'

# Project.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::Project
  def initialize(pgsql, id)
    @pgsql = pgsql
    @id = id
  end

  def login
    @pgsql.exec('SELECT login FROM project WHERE id = $1', [@id])[0]['login']
  end
end
