# frozen_string_literal: true

# Copyright (c) 2019-2020 Yegor Bugayenko
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

# Telechats.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2020 Yegor Bugayenko
# License:: MIT
class Rsk::Telechats
  def initialize(pgsql)
    @pgsql = pgsql
  end

  def add(id, login)
    @pgsql.exec(
      'INSERT INTO telechat (id, login) VALUES ($1, $2)',
      [id, login]
    )
  end

  def exists?(id)
    !@pgsql.exec('SELECT * FROM telechat WHERE id = $1', [id]).empty?
  end

  def wired?(login)
    !@pgsql.exec('SELECT * FROM telechat WHERE login = $1', [login]).empty?
  end

  def login_of(id)
    @pgsql.exec('SELECT login FROM telechat WHERE id = $1', [id])[0]['login']
  end

  def chat_of(login)
    @pgsql.exec('SELECT id FROM telechat WHERE login = $1', [login])[0]['id'].to_i
  end

  # This message was just posted.
  def posted(msg, chat)
    @pgsql.exec('UPDATE telechat SET recent = $1 WHERE id = $2', [msg, chat])
  end

  # This message is different from the last posted?
  def diff?(msg, chat)
    @pgsql.exec('SELECT recent FROM telechat WHERE id = $1', [chat])[0]['recent'] != msg
  end
end
