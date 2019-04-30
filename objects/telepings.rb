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

# Telepings.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019 Yegor Bugayenko
# License:: MIT
class Rsk::Telepings
  def initialize(pgsql)
    @pgsql = pgsql
  end

  def add(task, chat)
    @pgsql.exec(
      'INSERT INTO teleping (task, telechat) VALUES ($1, $2)',
      [task, chat]
    )
  end

  # Returns a list of task IDs, which need to be pinged ASAP.
  def expired(login)
    @pgsql.exec(
      [
        'SELECT id FROM',
        '(SELECT task.id AS id, MAX(teleping.created) AS latest FROM task',
        'JOIN plan ON task.plan = plan.id',
        'JOIN part ON plan.part = part.id',
        'JOIN project ON project.id = part.project',
        'LEFT JOIN teleping ON teleping.task = task.id',
        'WHERE project.login = $1',
        'GROUP BY task.id) t',
        'WHERE latest IS NULL or latest < NOW() - INTERVAL \'4 DAYS\''
      ],
      [login]
    ).map { |r| r['id'].to_i }
  end
end
