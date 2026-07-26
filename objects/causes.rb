# frozen_string_literal: true

require_relative 'cause'
require_relative 'query'
# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'

class Rsk::Causes
  def initialize(pgsql, project)
    @pgsql = pgsql
    @project = project
  end

  def add(text)
    @pgsql.transaction do |t|
      id = Integer(
        t.exec(
          'INSERT INTO part (project, text, type) VALUES ($1, $2, $3) RETURNING id',
          [@project, text, 'Cause']
        )[0]['id']
      )
      t.exec('INSERT INTO cause (id) VALUES ($1)', [id])
      id
    end
  end

  def emojis
    (
      @pgsql.exec(
        [
          'SELECT DISTINCT emoji FROM cause',
          'JOIN part ON part.id = cause.id',
          'WHERE project = $1'
        ],
        [@project]
      ).map { |r| r['emoji'] } + ['💰', '💾', '🏢', '🤵', '📚', '📦']
    ).uniq
  end

  def get(id)
    require_relative('cause')
    Rsk::Cause.new(@pgsql, id)
  end

  def count(query: '')
    query(query).count
  end

  def fetch(query: '', limit: 10, offset: 0)
    query(query).fetch(offset, limit).map do |r|
      {
        id: Integer(r['id']),
        text: r['text'],
        emoji: r['emoji'],
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
        'SELECT cause.*, part.text,',
        '  SUM(risk.probability * effect.impact) / COUNT(risk.id) AS rank,',
        '  COUNT(risk.id) AS risks',
        'FROM cause',
        'JOIN part ON part.id = cause.id',
        'LEFT JOIN triple ON triple.cause = cause.id',
        'LEFT JOIN risk ON triple.risk = risk.id',
        'LEFT JOIN effect ON triple.effect = effect.id',
        'WHERE project = $1 AND (LOWER(text) LIKE $2 OR emoji LIKE $2)',
        'GROUP BY cause.id, part.id',
        'ORDER BY rank DESC'
      ],
      [@project, "%#{query.to_s.downcase.strip.gsub(/[%_]/, '\\\\\0')}%"]
    )
  end
end
