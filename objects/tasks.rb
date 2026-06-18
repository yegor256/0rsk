# frozen_string_literal: true

require_relative 'pipeline'
require_relative 'plans'
require_relative 'query'
# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'

class Rsk::Tasks
  THRESHOLD = 8

  def initialize(pgsql, login)
    @pgsql = pgsql
    @login = login
  end

  def create
    Rsk::Pipeline.new(@pgsql, @login).fetch.each do |p|
      next if count >= THRESHOLD
      @pgsql.exec('INSERT INTO task (plan) VALUES ($1)', [p])
    end
  end

  def done(id)
    row = plan(id)
    @pgsql.transaction do |t|
      t.exec('DELETE FROM task WHERE id = $1', [id])
      Rsk::Plans.new(@pgsql, Integer(row['project'] || 0)).get(Integer(row['id']), Integer(row['part'])).complete
    end
  end

  def postpone(id, seconds)
    row = plan(id)
    @pgsql.transaction do |t|
      t.exec('DELETE FROM task WHERE id = $1', [id])
      plan = Rsk::Plans.new(@pgsql, Integer(row['project'] || 0)).get(Integer(row['id']), Integer(row['part']))
      raise(Rsk::Urror, "Can't postpone plan ##{row['id']}") if /^[a-z]+$/.match?(plan.schedule)
      plan.reschedule((Time.now + seconds).strftime('%d-%m-%Y'))
    end
  end

  def count(query: '')
    query(query).count
  end

  def fetch(query: '', limit: 10, offset: 0)
    query(query).fetch(offset, limit).map do |r|
      {
        id: Integer(r['id']),
        pid: Integer(r['pid']),
        emoji: r['emoji'],
        rank: Integer(r['rank']),
        positive: r['positive'] == 't',
        triple: Integer(r['tid']),
        prefix: r['prefix'],
        title: r['title'],
        plan: Integer(r['plan']),
        part: Integer(r['part']),
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

  def plan(id)
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
    raise(Rsk::Urror, "Task ##{id} not found in projects of #{@login}") if project.nil?
    raise(Rsk::Urror, "Task ##{id} doesn't belong to #{@login}") if project['login'] != @login
    row = @pgsql.exec('SELECT plan.* FROM plan JOIN task ON task.plan = plan.id WHERE task.id = $1', [id])[0]
    raise(Rsk::Urror, "Plan for task ##{id} not found") if row.nil?
    row
  end
end
