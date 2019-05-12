# frozen_string_literal: true

# Copyright (c) 2019 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require_relative 'rsk'
require_relative 'risk'

# Risks.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019 Yegor Bugayenko
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

  def count
    @pgsql.exec(
      'SELECT COUNT(risk.id) FROM risk JOIN part ON part.id = risk.id WHERE project = $1',
      [@project]
    )[0]['count'].to_i
  end

  def fetch(query: '', limit: 10, offset: 0)
    rows = @pgsql.exec(
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
        'ORDER BY rank DESC',
        'OFFSET $3 LIMIT $4'
      ],
      [@project, "%#{query.to_s.downcase.strip}%", offset, limit]
    )
    rows.map do |r|
      {
        id: r['id'].to_i,
        text: r['text'],
        probability: r['probability'].to_i,
        rank: r['rank'].to_i,
        effects: r['effects'].to_i
      }
    end
  end
end
