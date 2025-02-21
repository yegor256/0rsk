# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# SQL Query builder.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::Query
  def initialize(pgsql, sql, params)
    @pgsql = pgsql
    @sql = sql
    @params = params
  end

  def fetch(offset, limit)
    @pgsql.exec(@sql + ["OFFSET #{offset.to_i} LIMIT #{limit.to_i}"], @params)
  end

  def count
    @pgsql.exec(['SELECT COUNT(*) FROM ('] + @sql + [') x'], @params)[0]['count'].to_i
  end
end
