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
    @pgsql.exec(
      'INSERT INTO link (project, a, b) VALUES ($1, $2, $3) RETURNING id',
      [@project, real(left), real(right)]
    )[0]['id'].to_i
  end

  private

  def real(path)
    raise "Invalid path #{path.inspect}" unless /^[CREP][0-9]+$/.match?(path)
    id = path[1..-1].to_i
    case path[0]
    when 'C'
      raise "Cause #{id} not found" unless Rsk::Causes.new(@pgsql, @project).exists?(id)
    when 'R'
      raise "Risk #{id} not found" unless Rsk::Risks.new(@pgsql, @project).exists?(id)
    when 'E'
      raise "Effect #{id} not found" unless Rsk::Effects.new(@pgsql, @project).exists?(id)
    when 'P'
      raise "Plan #{id} not found" unless Rsk::Plans.new(@pgsql, @project).exists?(id)
    else
      raise "Invalid prefix in #{path.inspect}"
    end
    path
  end
end
