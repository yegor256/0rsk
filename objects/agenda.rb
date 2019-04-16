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
require_relative 'links'

# Agenda.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019 Yegor Bugayenko
# License:: MIT
class Rsk::Agenda
  def initialize(pgsql, login)
    @pgsql = pgsql
    @login = login
  end

  # Analyze this plan.
  def analyze(pid)
    plan = Rsk::Plan.new(@pgsql, pid)
    @pgsql.exec(
      [
        'INSERT INTO agenda (login, plan, deadline, text, path)',
        'VALUES ($1, $2, $3, $4, $5)',
        'ON CONFLICT(plan) DO UPDATE SET deadline = $3, text = $4, path = $5'
      ].join(' '),
      [@login, pid, deadline(plan), text(plan), path(plan)]
    )
  end

  # Fetch it all.
  def fetch(query: '', offset: 0, limit: 50, days: 7)
    rows = @pgsql.exec(
      [
        'SELECT * FROM agenda',
        'WHERE login = $1',
        'AND LOWER(text) LIKE $2',
        "AND deadline < NOW() + INTERVAL \'#{days} DAYS\'",
        'ORDER BY deadline ASC',
        'OFFSET $3 LIMIT $4'
      ].join(' '),
      [@login, "%#{query.strip.downcase}%", offset, limit]
    )
    rows.map do |r|
      {
        id: r['id'].to_i,
        text: r['text'],
        chunks: r['path'].split(' '),
        deadline: Time.parse(r['deadline']),
        plan: Rsk::Plan.new(@pgsql, r['plan'].to_i),
        created: Time.parse(r['created'])
      }
    end
  end

  def refresh
    @pgsql.exec('SELECT * FROM agenda WHERE login = $1 AND deadline < NOW()', [@login]).each do |r|
      done(r['plan'].to_i)
    end
  end

  def done(pid)
    plan = Rsk::Plan.new(@pgsql, pid)
    @pgsql.exec('UPDATE agenda SET deadline = $1 WHERE id = $2', [deadline(plan), pid])
  end

  private

  def deadline(plan)
    schedule = plan.schedule.strip.downcase
    if schedule == 'weekly'
      Time.now + 3 * 24 * 60 * 60
    elsif schedule == 'biweekly'
      Time.now + 7 * 24 * 60 * 60
    elsif schedule == 'monthly'
      Time.now + 14 * 24 * 60 * 60
    elsif /^[0-9]{2}-[0-9]{2}-[0-9]{4}$/.match?(schedule)
      time = Time.parse(schedule)
      time < Time.now ? Time.now + 60 * 60 : time
    else
      Time.now + 60 * 60
    end
  end

  def project_of(pid)
    @pgsql.exec('SELECT project FROM plan WHERE id = $1', [pid])[0]['project'].to_i
  end

  def text(plan)
    links = Rsk::Links.new(@pgsql, project_of(plan.id))
    plan.text + ': ' + parents(links, plan.chunk).map do |p|
      links.item(p).text
    end.join('; ')
  end

  def path(plan)
    links = Rsk::Links.new(@pgsql, project_of(plan.id))
    parents(links, plan.chunk).join(' ')
  end

  def parents(links, chunk)
    lefts = links.left_of(chunk)
    return lefts if lefts.empty?
    (lefts + lefts.map { |c| parents(links, c) }).flatten.uniq.sort_by { |c| %w[C R E P].index(c[0]) }
  end
end
