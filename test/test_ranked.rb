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

require 'minitest/autorun'
require 'rack/test'
require_relative 'test__helper'
require_relative '../objects/rsk'
require_relative '../objects/ranked'
require_relative '../objects/causes'
require_relative '../objects/risks'
require_relative '../objects/effects'
require_relative '../objects/projects'

# Test of Ranked.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019 Yegor Bugayenko
# License:: MIT
class Rsk::RankedTest < Minitest::Test
  def test_adds_and_analyzes
    pid = Rsk::Projects.new(test_pgsql, 'jeff31').add('test')
    cid = Rsk::Causes.new(test_pgsql, pid).add('we have data')
    rid = Rsk::Risks.new(test_pgsql, pid).add('we may lose it')
    eid = Rsk::Effects.new(test_pgsql, pid).add('business will stop')
    links = Rsk::Links.new(test_pgsql, pid)
    links.add("C#{cid}", "R#{rid}")
    links.add("R#{rid}", "E#{eid}")
    ranked = Rsk::Ranked.new(test_pgsql, pid)
    ids = ranked.analyze("C#{cid}")
    ranked.analyze("C#{cid}")
    assert(!ids.empty?)
    i = ranked.fetch(chunks: ["C#{cid}"])[0]
    assert_equal('CRE', i[:mnemo])
    assert_equal(["C#{cid}", "R#{rid}", "E#{eid}"], i[:chunks])
    ranked.delete(ids.first)
  end

  def test_analyzes_non_standard_path
    project = Rsk::Projects.new(test_pgsql, 'jeff377').add('test')
    cid = Rsk::Causes.new(test_pgsql, project).add('we have data')
    rid = Rsk::Risks.new(test_pgsql, project).add('we may lose it')
    pid = Rsk::Plans.new(test_pgsql, project).add('fight!')
    links = Rsk::Links.new(test_pgsql, project)
    links.add("C#{cid}", "R#{rid}")
    links.add("R#{rid}", "P#{pid}")
    ranked = Rsk::Ranked.new(test_pgsql, project)
    ranked.analyze("C#{cid}")
  end
end
