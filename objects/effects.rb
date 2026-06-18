# frozen_string_literal: true

require_relative 'effect'
require_relative 'query'
# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'

class Rsk::Effects
  def initialize(pgsql, project)
    @pgsql = pgsql
    @project = project
  end

  def add(text)
    @pgsql.transaction do |t|
      id = Integer(
        t.exec(
          'INSERT INTO part (project, text, type) VALUES ($1, $2, $3) RETURNING id',
          [@project, text, 'Effect']
        )[0]['id']
      )
      t.exec('INSERT INTO effect (id) VALUES ($1)', [id])
      id
    end
  end

  def get(id)
    require_relative('effect')
    Rsk::Effect.new(@pgsql, id)
  end

  def count(query: '')
    query(query).count
  end

  def fetch(query: '', limit: 10, offset: 0)
    query(query).fetch(offset, limit).map do |r|
      {
        id: Integer(r['id']),
        text: r['text'],
        impact: Integer(r['impact']),
        positive: r['positive'] == 't',
        rank: Integer(r['rank'] || 0),
        risks: Integer(r['risks'])
      }
    end
  end

  private

  def query(query)
    Rsk::Query.new(
      @pgsql,
      [
        'SELECT effect.*, part.text AS text,',
        '  SUM(risk.probability) AS probability,',
        '  effect.impact * SUM(risk.probability) / COUNT(risk.id) AS rank,',
        '  COUNT(risk.id) AS risks',
        'FROM effect',
        'JOIN part ON part.id = effect.id',
        'LEFT JOIN triple ON triple.effect = effect.id',
        'LEFT JOIN risk ON triple.risk = risk.id',
        'WHERE project = $1',
        'AND LOWER(text) LIKE $2',
        'GROUP BY effect.id, part.id',
        'ORDER BY rank DESC'
      ],
      [@project, "%#{query.to_s.downcase.strip}%"]
    )
  end
end
