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
        'SUM(risk.probability * effect.impact)::numeric / COUNT(triple.id) AS rank',
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
    case schedule
    when 'daily'
      completed + (24 * 60 * 60)
    when 'weekly'
      completed + (7 * 24 * 60 * 60)
    when 'biweekly'
      completed + (14 * 24 * 60 * 60)
    when 'monthly'
      completed + (30 * 24 * 60 * 60)
    when 'quarterly'
      completed + (3 * 30 * 24 * 60 * 60)
    when 'annually'
      date = Date.new(completed.year, completed.month, completed.day) >> 12
      Time.new(date.year, date.month, date.day, completed.hour, completed.min, completed.sec, completed.utc_offset)
    when /^[0-9]{2}-[0-9]{2}-[0-9]{4}$/
      Time.parse(schedule)
    else
      completed
    end
  end
end
