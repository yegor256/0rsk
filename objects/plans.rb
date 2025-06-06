# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'
require_relative 'plan'
require_relative 'query'

# Plans.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::Plans
  def initialize(pgsql, project)
    @pgsql = pgsql
    @project = project
  end

  # Returns plan ID.
  def add(part, text)
    @pgsql.transaction do |t|
      id = t.exec(
        'INSERT INTO part (project, text, type) VALUES ($1, $2, $3) RETURNING id',
        [@project, text, 'Plan']
      )[0]['id'].to_i
      t.exec('INSERT INTO plan (id, part) VALUES ($1, $2)', [id, part])
      id
    end
  end

  def get(id, part)
    require_relative 'plan'
    Rsk::Plan.new(@pgsql, id, part)
  end

  def count(query: '')
    query(query).count
  end

  def fetch(query: '', limit: 10, offset: 0)
    query(query).fetch(offset, limit).map do |r|
      {
        id: r['id'].to_i,
        triple: r['tid'].to_i,
        text: r['text'],
        prefix: r['prefix'],
        positive: r['positive'] == 't',
        part: r['pid'].to_i,
        rank: r['rank'].to_i,
        completed: Time.parse(r['completed']),
        schedule: r['schedule']
      }
    end
  end

  private

  def query(query)
    Rsk::Query.new(
      @pgsql,
      [
        'SELECT plan.*, part.text, plan.part AS pid,',
        '  triple.id AS tid,',
        '  effect.positive AS positive,',
        '  CASE WHEN p.type = \'Cause\' THEN \'C\' WHEN p.type = \'Risk\' THEN \'R\' ELSE \'E\' END AS prefix,',
        '  (risk.probability * effect.impact) AS rank',
        'FROM plan',
        'JOIN part ON plan.id = part.id',
        'JOIN part AS p ON plan.part = p.id',
        'LEFT JOIN triple ON cause = plan.part OR risk = plan.part OR effect = plan.part',
        'LEFT JOIN risk ON risk.id = triple.risk',
        'LEFT JOIN effect ON effect.id = triple.effect',
        'WHERE part.project = $1',
        'AND',
        query.is_a?(Integer) ? 'triple.id = $2' : 'LOWER(part.text) LIKE $2',
        'ORDER BY rank DESC'
      ],
      [@project, query.is_a?(Integer) ? query : "%#{query.to_s.downcase.strip}%"]
    )
  end
end
