# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'
require_relative 'risk'
require_relative 'query'

# Risks.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::Risks
  def initialize(pgsql, project)
    @pgsql = pgsql
    @project = project
  end

  def add(text)
    @pgsql.transaction do |t|
      id = t.exec(
        'INSERT INTO part (project, text, type) VALUES ($1, $2, $3) RETURNING id',
        [@project, text, 'Risk']
      )[0]['id'].to_i
      t.exec('INSERT INTO risk (id) VALUES ($1)', [id])
      id
    end
  end

  def get(id)
    require_relative 'risk'
    Rsk::Risk.new(@pgsql, id)
  end

  def count(query: '')
    query(query).count
  end

  def fetch(query: '', limit: 10, offset: 0)
    query(query).fetch(offset, limit).map do |r|
      {
        id: r['id'].to_i,
        text: r['text'],
        probability: r['probability'].to_i,
        rank: r['rank'].to_i,
        effects: r['effects'].to_i
      }
    end
  end

  private

  def query(query)
    Rsk::Query.new(
      @pgsql,
      [
        'SELECT risk.*, part.text AS text,',
        '  SUM(effect.impact) AS impact,',
        '  risk.probability * SUM(effect.impact) / COUNT(effect.id) AS rank,',
        '  COUNT(effect.id) AS effects',
        'FROM risk',
        'JOIN part ON part.id = risk.id',
        'LEFT JOIN triple ON triple.risk = risk.id',
        'LEFT JOIN effect ON triple.effect = effect.id',
        'WHERE project = $1 AND LOWER(text) LIKE $2',
        'GROUP BY risk.id, part.id',
        'ORDER BY rank DESC'
      ],
      [@project, "%#{query.to_s.downcase.strip}%"]
    )
  end
end
