# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'

# Telepings.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::Telepings
  def initialize(pgsql)
    @pgsql = pgsql
  end

  def add(task, chat)
    @pgsql.exec(
      [
        'INSERT INTO teleping (task, telechat)',
        'VALUES ($1, $2)',
        'ON CONFLICT (task, telechat) DO UPDATE SET updated = NOW()'
      ],
      [task, chat]
    )
  end

  # Ping required for this user?
  def required(login, hours: 4)
    max = @pgsql.exec(
      [
        'SELECT MAX(teleping.updated) FROM teleping',
        'JOIN task ON teleping.task = task.id',
        'JOIN plan ON task.plan = plan.id',
        'JOIN part ON plan.part = part.id',
        'JOIN project ON project.id = part.project',
        'WHERE project.login = $1'
      ],
      [login]
    )[0]['max']
    return true if max.nil?
    Time.parse(max) < Time.now - (hours * 60 * 60)
  end

  # Returns a list of task IDs, which were not notified yet.
  def fresh(login)
    @pgsql.exec(
      [
        'SELECT task.id FROM task',
        'LEFT JOIN teleping ON teleping.task = task.id',
        'JOIN plan ON task.plan = plan.id',
        'JOIN part ON plan.part = part.id',
        'JOIN project ON project.id = part.project',
        'WHERE project.login = $1',
        'AND teleping.id IS NULL',
        'GROUP BY task.id'
      ],
      [login]
    ).map { |r| r['id'].to_i }
  end
end
