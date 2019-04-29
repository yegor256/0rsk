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

# Triples.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019 Yegor Bugayenko
# License:: MIT
class Rsk::Triples
  def initialize(pgsql, project)
    @pgsql = pgsql
    @project = project
  end

  def add(cid, rid, eid)
    @pgsql.exec(
      [
        'INSERT INTO triple (cause, risk, effect)',
        'VALUES ($1, $2, $3)',
        'ON CONFLICT(cause, risk, effect) DO NOTHING',
        'RETURNING id'
      ],
      [cid, rid, eid]
    )
  end

  def delete(id)
    @pgsql.transaction do |t|
      triple = fetch(query: id.to_i)[0]
      raise Rsk::Urror, "Triple ##{id} not found in your project ##{@project}" if triple.nil?
      if t.exec('SELECT * FROM part WHERE id = $1 AND project = $2', [triple[:cid], @project]).empty?
        raise Rsk::Urror, "Triple ##{id} is not in your project ##{@project}"
      end
      t.exec('DELETE FROM triple WHERE id = $1', [id])
      if t.exec('SELECT * FROM triple WHERE cause = $1', [triple[:cid]]).empty?
        t.exec('DELETE FROM part WHERE id = $1', [triple[:cid]])
      end
      if t.exec('SELECT * FROM triple WHERE risk = $1', [triple[:rid]]).empty?
        t.exec('DELETE FROM part WHERE id = $1', [triple[:rid]])
      end
      if t.exec('SELECT * FROM triple WHERE effect = $1', [triple[:eid]]).empty?
        t.exec('DELETE FROM part WHERE id = $1', [triple[:eid]])
      end
    end
  end

  def fetch(query: '', limit: 10, offset: 0)
    rows = @pgsql.exec(
      [
        'SELECT triple.id, cause.id AS cid, risk.id AS rid, effect.id AS eid,',
        '  risk.probability AS probability, effect.impact AS impact,',
        '  cpart.text AS ctext, rpart.text AS rtext, epart.text AS etext,',
        '  (probability * impact) AS rank FROM triple',
        'JOIN cause ON cause.id = triple.cause',
        'JOIN part AS cpart ON cause.id = cpart.id',
        'JOIN risk ON risk.id = triple.risk',
        'JOIN part AS rpart ON risk.id = rpart.id',
        'JOIN effect ON effect.id = triple.effect',
        'JOIN part AS epart ON effect.id = epart.id',
        'WHERE cpart.project = $1 AND rpart.project = $1 AND epart.project = $1',
        'AND',
        query.is_a?(Integer) ? "triple.id = #{query} AND (cpart.text = $2 OR cpart.text != $2)" :
          '(cpart.text LIKE $2 OR rpart.text LIKE $2 OR epart.text LIKE $2)',
        'ORDER BY rank DESC',
        'OFFSET $3 LIMIT $4'
      ],
      [@project, "%#{query}%", offset, limit]
    )
    rows.map do |r|
      {
        id: r['id'].to_i,
        cid: r['cid'].to_i,
        rid: r['rid'].to_i,
        eid: r['eid'].to_i,
        ctext: r['ctext'],
        rtext: r['rtext'],
        etext: r['etext'],
        probability: r['probability'].to_i,
        impact: r['impact'].to_i,
        rank: r['rank'].to_i
      }
    end
  end
end
