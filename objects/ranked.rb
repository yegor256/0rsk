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

# Ranked.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019 Yegor Bugayenko
# License:: MIT
class Rsk::Ranked
  def initialize(pgsql, project)
    @pgsql = pgsql
    @project = project
  end

  # For example: mnemo="CR", path="[C43] [R89]"
  def analyze(mnemo, path)
    rank = 1
    text = 'hey'
    @pgsql.exec(
      'INSERT INTO ranked (project, rank, mnemo, path, text) VALUES ($1, $2, $3, $4, $5) RETURNING id',
      [@project, rank, mnemo, path, text]
    )[0]['id'].to_i
  end

  def fetch(offset: 0, limit: 50)
    @pgsql.exec('SELECT * FROM ranked WHERE project = $1 OFFSET $2 LIMIT $3', [@project, offset, limit]).map do |r|
      {
        id: r['id'].to_i,
        rank: r['rank'].to_i,
        mnemo: r['mnemo'],
        path: r['path'],
        text: r['text'],
        created: Time.parse(r['created'])
      }
    end
  end
end
