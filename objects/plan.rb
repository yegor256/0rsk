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
require_relative 'urror'

# Plan.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019 Yegor Bugayenko
# License:: MIT
class Rsk::Plan
  attr_reader :id, :part

  def initialize(pgsql, id, part)
    @pgsql = pgsql
    @id = id
    @part = part
  end

  def detach
    @pgsql.transaction do |t|
      if t.exec('SELECT * FROM part WHERE id = $1 AND part = $2 AND project = $2', [@id, @part, pid]).empty?
        raise Rsk::Urror, "##{@id} is not in your project ##{pid}"
      end
      t.exec('DELETE FROM plan WHERE id = $1 AND part = $2', [@id, @part])
      t.exec('DELETE FROM part WHERE id = $1', [@id]) if t.exec('SELECT * FROM plan WHERE id = $1', [@id]).empty?
    end
  end

  # Set it as complete, with the completion time slighly in the past. This
  # is done in order to let the task be generated again at the same time
  # next day if it was completed "daily".
  def complete(time: Time.now - 4 * 60 * 60)
    if /^[a-z]+$/.match?(schedule)
      @pgsql.exec('UPDATE plan SET completed = $3 WHERE id = $1 AND part = $2', [@id, @part, time])
    else
      detach
    end
  end

  def schedule
    @pgsql.exec('SELECT schedule FROM plan WHERE id = $1 AND part = $2', [@id, @part])[0]['schedule']
  end

  def schedule=(text)
    unless /^(daily|weekly|biweekly|monthly|quarterly|annually|\d{2}-\d{2}-\d{4})$/.match?(text)
      raise Rsk::Urror, "Schedule can either be a word or a date DD-MM-YYYY: #{text.inspect}"
    end
    @pgsql.exec('UPDATE plan SET schedule = $3 WHERE id = $1 AND part = $2', [@id, @part, text])
  end

  private

  def pid
    @pgsql.exec('SELECT project FROM part WHERE id = $1', [@id])[0]['project'].to_i
  end
end
