# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

class Rsk::Query
  def initialize(pgsql, sql, params)
    @pgsql = pgsql
    @sql = sql
    @params = params
  end

  def fetch(offset, limit)
    @pgsql.exec(@sql + ["OFFSET #{Integer(offset)} LIMIT #{Integer(limit)}"], @params)
  end

  def count
    Integer(@pgsql.exec(['SELECT COUNT(*) FROM ('] + @sql + [') x'], @params)[0]['count'])
  end
end
