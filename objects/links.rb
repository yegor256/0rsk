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
require_relative 'causes'
require_relative 'risks'
require_relative 'effects'
require_relative 'plans'

# Links.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019 Yegor Bugayenko
# License:: MIT
class Rsk::Links
  def initialize(pgsql, project)
    @pgsql = pgsql
    @project = project
  end

  def add(left, right)
    a = item(left)
    b = item(right)
    order = %w[C R E P]
    raise "#{a.chunk} can't link to #{b.chunk}" if a.mnemo == b.mnemo
    raise "#{a.chunk} can't preceed #{b.chunk}" if order.index(a.mnemo) > order.index(b.mnemo)
    @pgsql.exec(
      'INSERT INTO link (project, a, b) VALUES ($1, $2, $3) ON CONFLICT(project, a, b) DO NOTHING',
      [@project, a.chunk, b.chunk]
    )
  end

  def right_of(chunk)
    @pgsql.exec(
      'SELECT b FROM link WHERE project = $1 AND a = $2',
      [@project, chunk]
    ).map { |r| r['b'] }
  end

  def left_of(chunk)
    @pgsql.exec(
      'SELECT a FROM link WHERE project = $1 AND b = $2',
      [@project, chunk]
    ).map { |r| r['a'] }
  end

  def item(path)
    raise "Invalid path #{path.inspect}" unless /^[CREP][0-9]+$/.match?(path)
    id = path[1..-1].to_i
    bag = bag(path[0])
    unless bag.exists?(id)
      raise "#{path.inspect}: #{bag.class.name.split('::').last}/#{id} not found in the project ##{@project}"
    end
    bag.get(id)
  end

  private

  def bag(prefix)
    case prefix
    when 'C'
      Rsk::Causes.new(@pgsql, @project)
    when 'R'
      Rsk::Risks.new(@pgsql, @project)
    when 'E'
      Rsk::Effects.new(@pgsql, @project)
    when 'P'
      Rsk::Plans.new(@pgsql, @project)
    else
      raise "Invalid prefix #{prefix.inspect}"
    end
  end
end
