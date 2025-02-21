# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'time'

# Pipeline of plans.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::Pipeline
  def initialize(pgsql, login)
    @pgsql = pgsql
    @login = login
  end

  # Fetch all plans that are good to go into tasks right now.
  def fetch
    plans = @pgsql.exec(
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
        'GROUP BY plan.id, plan.completed, plan.schedule'
      ],
      [@login]
    )
    plans.select { |p| deadline(Time.parse(p['completed']), p['schedule'].strip.downcase) < Time.now }
      .map { |p| p['id'].to_i }
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
      completed + (12 * 30 * 24 * 60 * 60)
    when /^[0-9]{2}-[0-9]{2}-[0-9]{4}$/
      Time.parse(schedule)
    else
      completed
    end
  end
end
