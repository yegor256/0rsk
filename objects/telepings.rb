# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'

# Telepings.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2026 Yegor Bugayenko
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

  # Resolve fresh task ids into their hashes and drop any that the supplied
  # +tasks+ collection cannot fetch. The +fresh+ predicate is wider than
  # Tasks#fetch (it does not require a triple), so the two diverge whenever
  # a plan's part is not (yet) wired into a triple, or when the task is
  # deleted between calls. The result is sorted by rank, descending.
  def fresh_tasks(login, tasks)
    fresh(login)
      .filter_map { |tid| tasks.fetch(query: tid)[0] }
      .sort_by { |t| t[:rank] }
      .reverse
  end
end
