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

require 'time'

# Pipeline of plans.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019 Yegor Bugayenko
# License:: MIT
class Rsk::Pipeline
  def initialize(pgsql, login)
    @pgsql = pgsql
    @login = login
  end

  # Fetch all plans that are good to go into tasks right now.
  def fetch
    plans = @pgsql.exec(
      [
        'SELECT plan.id, plan.completed, plan.schedule,',
        'SUM(risk.probability * effect.impact) / COUNT(triple.id) AS rank',
        'FROM plan',
        'JOIN part ON part.id = plan.part',
        'JOIN project ON part.project = project.id',
        'JOIN triple ON cause = plan.part OR risk = plan.part OR effect = plan.part',
        'JOIN risk ON triple.risk = risk.id',
        'JOIN effect ON triple.effect = effect.id',
        'LEFT JOIN task ON task.plan = plan.id',
        'WHERE project.login = $1 AND task.id IS NULL',
        'GROUP BY plan.id, plan.completed, plan.schedule'
      ],
      [@login]
    )
    plans.select { |p| deadline(Time.parse(p['completed']), p['schedule'].strip.downcase) < Time.now }
      .map { |p| p['id'].to_i }
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
