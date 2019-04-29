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
require_relative 'cause'
require_relative 'urror'

# Causes.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019 Yegor Bugayenko
# License:: MIT
class Rsk::Causes
  def initialize(pgsql, project)
    @pgsql = pgsql
    @project = project
  end

  def add(text)
    @pgsql.transaction do |t|
      id = t.exec(
        'INSERT INTO part (project, text, type) VALUES ($1, $2, $3) RETURNING id',
        [@project, text, 'Cause']
      )[0]['id'].to_i
      t.exec('INSERT INTO cause (id) VALUES ($1)', [id])
      id
    end
  end

  def get(id)
    require_relative 'cause'
    Rsk::Cause.new(@pgsql, id)
  end

  def fetch(query: '', limit: 10, offset: 0)
    rows = @pgsql.exec(
      [
        'SELECT cause.*, part.text FROM cause',
        'JOIN part ON part.id = cause.id',
        'WHERE project = $1 AND text LIKE $2',
        'OFFSET $3 LIMIT $4'
      ].join(' '),
      [@project, "%#{query}%", offset, limit]
    )
    rows.map do |r|
      {
        id: r['id'].to_i,
        text: r['text']
      }
    end
  end
end
