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
require_relative 'plans'

# Tasks.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019 Yegor Bugayenko
# License:: MIT
class Rsk::Tasks
  def initialize(pgsql, login)
    @pgsql = pgsql
    @login = login
  end

  # Promote plans into tasks, if their schedules requre.
  def create
    plans = @pgsql.exec(
      [
        'SELECT plan.* FROM plan',
        'JOIN part ON part.id = plan.part',
        'JOIN project ON part.project = project.id',
        'LEFT JOIN task ON task.plan = plan.id',
        'WHERE project.login = $1 AND task.id IS NULL'
      ],
      [@login]
    )
    plans.each do |p|
      completed = Time.parse(p['completed'])
      deadline = deadline(completed, p['schedule'].strip.downcase)
      @pgsql.exec('INSERT INTO task (plan) VALUES ($1)', [p['id'].to_i]) if deadline < Time.now
    end
  end

  def done(id)
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
    @pgsql.transaction do |t|
      t.exec('DELETE FROM task WHERE id = $1', [id])
      Rsk::Plans.new(@pgsql, project['id'].to_i).complete(row['id'].to_i, row['part'].to_i)
    end
  end

  def fetch(query: '', limit: 10, offset: 0)
    rows = @pgsql.exec(
      [
        'SELECT task.*, plan.schedule AS schedule, plan.part AS part,',
        '  part.text AS text, t.text AS ptext,',
        '  project.id AS pid, project.title AS title,',
        '  triple.id AS tid,',
        '  CASE WHEN t.type = \'Cause\' THEN \'C\' WHEN t.type = \'Risk\' THEN \'R\' ELSE \'E\' END AS prefix',
        'FROM task',
        'JOIN plan ON plan.id = task.plan',
        'JOIN part ON plan.id = part.id',
        'JOIN triple ON risk = plan.part OR cause = plan.part OR effect = plan.part',
        'JOIN project ON part.project = project.id',
        'JOIN part AS t ON plan.part = t.id',
        'WHERE project.login = $1',
        'AND',
        query.is_a?(Integer) ? 'task.id = $2' : 'LOWER(part.text) LIKE $2',
        'OFFSET $3 LIMIT $4'
      ],
      [@login, query.is_a?(Integer) ? query : "%#{query.to_s.downcase.strip}%", offset, limit]
    )
    rows.map do |r|
      {
        id: r['id'].to_i,
        pid: r['pid'].to_i,
        triple: r['tid'].to_i,
        title: r['title'],
        plan: r['plan'].to_i,
        part: r['part'].to_i,
        text: r['text'],
        ptext: r['ptext'],
        schedule: r['schedule']
      }
    end
  end

  private

  def deadline(completed, schedule)
    if schedule == 'daily'
      completed + 24 * 60 * 60
    elsif schedule == 'weekly'
      completed + 7 * 24 * 60 * 60
    elsif schedule == 'biweekly'
      completed + 14 * 24 * 60 * 60
    elsif schedule == 'monthly'
      completed + 30 * 24 * 60 * 60
    elsif schedule == 'quarterly'
      completed + 3 * 30 * 24 * 60 * 60
    elsif schedule == 'annually'
      completed + 12 * 30 * 24 * 60 * 60
    elsif /^[0-9]{2}-[0-9]{2}-[0-9]{4}$/.match?(schedule)
      Time.parse(schedule)
    else
      completed
    end
  end
end
