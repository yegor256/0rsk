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
require_relative 'plan'
require_relative 'tasks'
require_relative 'project'

# Plans.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019 Yegor Bugayenko
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

  def detach(id, part)
    @pgsql.transaction do |t|
      if t.exec('SELECT * FROM part WHERE id = $1 AND project = $2', [id, @project]).empty?
        raise Rsk::Urror, "##{id} is not in your project ##{@project}"
      end
      t.exec('DELETE FROM plan WHERE id = $1 AND part = $2', [id, part])
      t.exec('DELETE FROM part WHERE id = $1', [id]) if t.exec('SELECT * FROM plan WHERE id = $1', [id]).empty?
    end
  end

  def complete(id, part)
    p = get(id)
    if /^[a-z]+$/.match?(p.schedule)
      @pgsql.exec('UPDATE plan SET completed = NOW() WHERE id = $1 AND part = $2', [id, part])
    else
      detach(id, part)
    end
  end

  def get(id)
    require_relative 'plan'
    Rsk::Plan.new(@pgsql, id)
  end

  def fetch(query: '', limit: 10, offset: 0)
    rows = @pgsql.exec(
      [
        'SELECT plan.*, part.text, plan.part AS pid,',
        'CASE WHEN p.type = \'Cause\' THEN \'C\' WHEN p.type = \'Risk\' THEN \'R\' ELSE \'E\' END AS prefix,',
        '(risk.probability * effect.impact) AS rank',
        'FROM plan',
        'JOIN part ON plan.id = part.id',
        'JOIN part AS p ON plan.part = p.id',
        'LEFT JOIN triple ON cause = plan.part OR risk = plan.part OR effect = plan.part',
        'LEFT JOIN risk ON risk.id = triple.risk',
        'LEFT JOIN effect ON effect.id = triple.effect',
        'WHERE part.project = $1',
        'AND',
        query.is_a?(Integer) ? 'triple.id = $2' : 'LOWER(part.text) LIKE $2',
        'ORDER BY rank DESC',
        'OFFSET $3 LIMIT $4'
      ],
      [@project, query.is_a?(Integer) ? query : "%#{query.to_s.downcase.strip}%", offset, limit]
    )
    rows.map do |r|
      {
        id: r['id'].to_i,
        text: r['text'],
        prefix: r['prefix'],
        part: r['pid'].to_i,
        rank: r['rank'].to_i,
        completed: Time.parse(r['completed']),
        schedule: r['schedule']
      }
    end
  end
end
