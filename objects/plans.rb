# frozen_string_literal: true

require_relative 'plan'
require_relative 'query'
# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'

class Rsk::Plans
  def initialize(pgsql, project)
    @pgsql = pgsql
    @project = project
  end

  def add(part, text)
    @pgsql.transaction do |t|
      id = Integer(
        t.exec(
          'INSERT INTO part (project, text, type) VALUES ($1, $2, $3) RETURNING id',
          [@project, text, 'Plan']
        )[0]['id']
      )
      t.exec('INSERT INTO plan (id, part) VALUES ($1, $2)', [id, part])
      id
    end
  end

  def get(id, part)
    require_relative('plan')
    Rsk::Plan.new(@pgsql, id, part)
  end

  def count(query: '')
    query(query).count
  end

  def fetch(query: '', limit: 10, offset: 0)
    query(query).fetch(offset, limit).map do |r|
      {
        id: Integer(r['id']),
        triple: Integer(r['tid'] || 0),
        text: r['text'],
        prefix: r['prefix'],
        positive: r['positive'] == 't',
        part: Integer(r['pid']),
        rank: Integer(r['rank'] || 0),
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
        'SELECT * FROM (',
        '  SELECT DISTINCT ON (plan.id) plan.*, part.text, plan.part AS pid,',
        '    triple.id AS tid,',
        '    effect.positive AS positive,',
        '    CASE WHEN p.type = \'Cause\' THEN \'C\' WHEN p.type = \'Risk\' THEN \'R\' ELSE \'E\' END AS prefix,',
        '    (risk.probability * effect.impact) AS rank',
        '  FROM plan',
        '  JOIN part ON plan.id = part.id',
        '  JOIN part AS p ON plan.part = p.id',
        '  LEFT JOIN triple ON cause = plan.part OR risk = plan.part OR effect = plan.part',
        '  LEFT JOIN risk ON risk.id = triple.risk',
        '  LEFT JOIN effect ON effect.id = triple.effect',
        '  WHERE part.project = $1',
        '  AND',
        '  ' + (query.is_a?(Integer) ? 'triple.id = $2' : 'LOWER(part.text) LIKE $2'),
        '  ORDER BY plan.id, rank DESC',
        ') sub',
        'ORDER BY rank DESC'
      ],
      [@project, query.is_a?(Integer) ? query : "%#{query.to_s.downcase.strip}%"]
    )
  end
end
