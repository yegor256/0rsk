# frozen_string_literal: true

# Copyright (c) 2019-2025 Yegor Bugayenko
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
require_relative 'plans'
require_relative 'query'
require_relative 'pipeline'

# Tasks.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::Tasks
  # Max allowed.
  THRESHOLD = 8

  def initialize(pgsql, login)
    @pgsql = pgsql
    @login = login
  end

  # Promote plans into tasks, if their schedules requre.
  def create
    Rsk::Pipeline.new(@pgsql, @login).fetch.each do |p|
      next if count >= THRESHOLD
      @pgsql.exec('INSERT INTO task (plan) VALUES ($1)', [p])
    end
  end

  # Close this task, remove it from the list and destroy the plan
  # it was attached to, if it was a one-time plan.
  def done(id)
    row = plan_of(id)
    @pgsql.transaction do |t|
      t.exec('DELETE FROM task WHERE id = $1', [id])
      Rsk::Plans.new(@pgsql, row['project'].to_i).get(row['id'].to_i, row['part'].to_i).complete
    end
  end

  # Postpone this task for some time.
  def postpone(id, seconds)
    row = plan_of(id)
    @pgsql.transaction do |t|
      t.exec('DELETE FROM task WHERE id = $1', [id])
      s = (Time.now + seconds).strftime('%d-%m-%Y')
      plan = Rsk::Plans.new(@pgsql, row['project'].to_i).get(row['id'].to_i, row['part'].to_i)
      raise Rsk::Urror, "Can't postpone plan ##{row['id']}" if /^[a-z]+$/.match?(plan.schedule)
      plan.schedule = s
    end
  end

  # Total amount of tasks in this user account.
  def count(query: '')
    query(query).count
  end

  # Fetch them all and return an array of hashes.
  def fetch(query: '', limit: 10, offset: 0)
    query(query).fetch(offset, limit).map do |r|
      {
        id: r['id'].to_i,
        pid: r['pid'].to_i,
        emoji: r['emoji'],
        rank: r['rank'].to_i,
        positive: r['positive'] == 't',
        triple: r['tid'].to_i,
        prefix: r['prefix'],
        title: r['title'],
        plan: r['plan'].to_i,
        part: r['part'].to_i,
        text: r['text'],
        ctext: r['ctext'],
        rtext: r['rtext'],
        etext: r['etext'],
        ptext: r['ptext'],
        schedule: r['schedule']
      }
    end
  end

  private

  def query(query)
    Rsk::Query.new(
      @pgsql,
      [
        'SELECT * FROM (SELECT DISTINCT ON (task.id) task.id, task.plan,',
        '  plan.schedule AS schedule, plan.part AS part,',
        '  emoji,',
        '  part.text AS text, t.text AS ptext,',
        '  project.id AS pid, project.title AS title,',
        '  triple.id AS tid,',
        '  risk.probability * effect.impact AS rank,',
        '  effect.positive AS positive,',
        '  cpart.text AS ctext, rpart.text AS rtext, epart.text AS etext,',
        '  CASE WHEN t.type = \'Cause\' THEN \'C\' WHEN t.type = \'Risk\' THEN \'R\' ELSE \'E\' END AS prefix',
        'FROM task',
        'JOIN plan ON plan.id = task.plan',
        'JOIN part ON plan.id = part.id',
        'JOIN triple ON risk = plan.part OR cause = plan.part OR effect = plan.part',
        'JOIN cause ON cause.id = triple.cause',
        'JOIN part AS cpart ON cause.id = cpart.id',
        'JOIN risk ON risk.id = triple.risk',
        'JOIN part AS rpart ON risk.id = rpart.id',
        'JOIN effect ON effect.id = triple.effect',
        'JOIN part AS epart ON effect.id = epart.id',
        'JOIN project ON part.project = project.id',
        'JOIN part AS t ON plan.part = t.id',
        'WHERE project.login = $1',
        'AND',
        query.is_a?(Integer) ? 'task.id = $2' : [
          '(emoji LIKE $2 OR LOWER(part.text) LIKE $2',
          'OR LOWER(cpart.text) LIKE $2',
          'OR LOWER(rpart.text) LIKE $2',
          'OR LOWER(epart.text) LIKE $2)'
        ].join(' '),
        'ORDER BY task.id ASC) x',
        'ORDER BY rank DESC'
      ],
      [@login, query.is_a?(Integer) ? query : "%#{query.to_s.downcase.strip}%"]
    )
  end

  # The plan of the task, the row.
  def plan_of(id)
    project = @pgsql.exec(
      [
        'SELECT project.* FROM project',
        'JOIN part ON part.project = project.id',
        'JOIN plan ON plan.id = part.id',
        'JOIN task ON task.plan = plan.id',
        'WHERE task.id = $1'
      ],
      [id]
    )[0]
    raise Rsk::Urror, "Task ##{id} not found in projects of #{@login}" if project.nil?
    raise Rsk::Urror, "Task ##{id} doesn't belong to #{@login}" if project['login'] != @login
    row = @pgsql.exec('SELECT plan.* FROM plan JOIN task ON task.plan = plan.id WHERE task.id = $1', [id])[0]
    raise Rsk::Urror, "Plan for task ##{id} not found" if row.nil?
    row
  end
end
