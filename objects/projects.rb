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

# Projects.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019 Yegor Bugayenko
# License:: MIT
class Rsk::Projects
  def initialize(pgsql, login)
    @pgsql = pgsql
    @login = login
  end

  def add(title)
    @pgsql.exec(
      'INSERT INTO project (login, title) VALUES ($1, $2) RETURNING id',
      [@login, title]
    )[0]['id'].to_i
  end

  def fetch
    @pgsql.exec('SELECT * FROM project WHERE login = $1', [@login]).map do |r|
      {
        id: r['id'].to_i,
        title: r['title'],
        created: Time.parse(r['created'])
      }
    end
  end

  def exists?(pid)
    !@pgsql.exec('SELECT * FROM project WHERE login = $1 AND id = $2', [@login, pid]).empty?
  end
end
