# frozen_string_literal: true

# Copyright (c) 2019-2024 Yegor Bugayenko
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
require_relative 'query'
require_relative 'urror'

# Triples.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2024 Yegor Bugayenko
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
        'ON CONFLICT(cause, risk, effect) DO UPDATE SET cause = $1',
        'RETURNING id'
      ],
      [cid, rid, eid]
    )[0]['id'].to_i
  end

  def delete(id)
    @pgsql.transaction do |t|
      triple = fetch(id: id.to_i)[0]
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

  def count(query: '')
    query(0, query).count
  end

  def fetch(id: 0, query: '', limit: 10, offset: 0)
    query(id, query).fetch(offset, limit).map do |r|
      {
        id: r['id'].to_i,
        cid: r['cid'].to_i,
        rid: r['rid'].to_i,
        eid: r['eid'].to_i,
        emoji: r['emoji'],
        ctext: r['ctext'],
        rtext: r['rtext'],
        etext: r['etext'],
        probability: r['probability'].to_i,
        impact: r['impact'].to_i,
        positive: r['positive'] == 't',
        rank: r['rank'].to_i,
        plans: r['plans'] == '{NULL}' ? [] : JSON.parse("[#{r['plans'][1..-2]}]").map do |p|
          id, text = p.split(':', 2)
          { id: id.to_i, text: text }
        end
      }
    end
  end

  private

  def query(id, query)
    where = []
    words = []
    unless id.positive?
      query.strip.downcase.split.each do |w|
        if w.start_with?('+')
          if w == '+alone'
            where << 'plan.id IS NULL'
          elsif /^\+[0-9]+$/.match?(w)
            p = w[1..].to_i
            where << "t.cause = #{p} OR t.risk = #{p} OR t.effect = #{p}"
          else
            raise Rsk::Urror, "Can't understand query operator #{w.inspect}"
          end
        else
          words << w
        end
      end
    end
    Rsk::Query.new(
      @pgsql,
      [
        'SELECT DISTINCT t.id, t.created, cause.id AS cid, risk.id AS rid, effect.id AS eid,',
        '  effect.positive,',
        '  cause.emoji,',
        '  risk.probability AS probability, effect.impact AS impact,',
        '  cpart.text AS ctext, rpart.text AS rtext, epart.text AS etext,',
        '  (probability * impact) AS rank,',
        '  ARRAY_AGG(ppart.id || \':\' || ppart.text || \' (\' || plan.schedule || \')\')',
        '    OVER (PARTITION BY t.id) AS plans',
        'FROM triple t',
        'JOIN cause ON cause.id = t.cause',
        'JOIN part AS cpart ON cause.id = cpart.id',
        'JOIN risk ON risk.id = t.risk',
        'JOIN part AS rpart ON risk.id = rpart.id',
        'JOIN effect ON effect.id = t.effect',
        'JOIN part AS epart ON effect.id = epart.id',
        'LEFT JOIN plan ON plan.part = t.cause OR plan.part = t.risk OR plan.part = t.effect',
        'LEFT JOIN part AS ppart ON plan.id = ppart.id',
        'WHERE cpart.project = $1 AND rpart.project = $1 AND epart.project = $1',
        'AND',
        id.positive? ?
          't.id = $2' :
          [
            '(emoji LIKE $2 OR LOWER(cpart.text) LIKE $2',
            '  OR LOWER(rpart.text) LIKE $2',
            '  OR LOWER(epart.text) LIKE $2',
            '  OR LOWER(ppart.text) LIKE $2)'
          ].join(' '),
        where.empty? ? '' : "AND (#{where.join(') AND (')})",
        'ORDER BY rank DESC, t.created DESC'
      ],
      [@project, id.positive? ? id : "%#{words.join(' ')}%"]
    )
  end
end
