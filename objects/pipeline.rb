# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'date'
require 'time'

class Rsk::Pipeline
  def initialize(pgsql, login)
    @pgsql = pgsql
    @login = login
  end

  def fetch
    @pgsql.exec(
      [
        'SELECT plan.id, plan.completed, plan.schedule,',
        'SUM(risk.probability * effect.impact) / COUNT(triple.id) AS rank',
        'FROM plan',
        'JOIN part ON part.id = plan.part',
        'JOIN project ON part.project = project.id',
        'JOIN triple ON cause = plan.part OR risk = plan.part OR effect = plan.part',
        'JOIN risk ON triple.risk = risk.id',
        'JOIN effect ON triple.effect = effect.id',
        'LEFT JOIN task ON task.plan = plan.id',
        'WHERE project.login = $1 AND task.id IS NULL',
        'GROUP BY plan.id, plan.completed, plan.schedule',
        'ORDER BY rank DESC'
      ],
      [@login]
    ).filter_map do |p|
      Integer(p['id']) if deadline(Time.parse(p['completed']), p['schedule'].strip.downcase) < Time.now
    end
  end

  private

  def deadline(completed, schedule)
    day = completed.to_date
    case schedule
    when 'daily'
      completed + (24 * 60 * 60)
    when 'weekly'
      completed + (7 * 24 * 60 * 60)
    when 'biweekly'
      completed + (14 * 24 * 60 * 60)
    when 'monthly'
      completed + (((day >> 1) - day) * 24 * 60 * 60)
    when 'quarterly'
      completed + (((day >> 3) - day) * 24 * 60 * 60)
    when 'annually'
      completed + (((day >> 12) - day) * 24 * 60 * 60)
    when /^[0-9]{2}-[0-9]{2}-[0-9]{4}$/
      Time.parse(schedule)
    else
      completed
    end
  end
end
