# frozen_string_literal: true

# Copyright (c) 2019-2023 Yegor Bugayenko
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
require_relative '../objects/causes'
require_relative '../objects/risks'
require_relative '../objects/effects'
require_relative '../objects/projects'
require_relative '../objects/triples'
require_relative '../objects/plans'

# Test of Triples.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2023 Yegor Bugayenko
# License:: MIT
class Rsk::TriplesTest < Minitest::Test
  def test_adds_and_fetches
    login = "sarah#{rand(99_999)}"
    project = Rsk::Projects.new(test_pgsql, login).add("test#{rand(99_999)}")
    cid = Rsk::Causes.new(test_pgsql, project).add('we have data')
    rid = Rsk::Risks.new(test_pgsql, project).add('we may lose it')
    eid = Rsk::Effects.new(test_pgsql, project).add('business will stop')
    triples = Rsk::Triples.new(test_pgsql, project)
    assert_equal(0, triples.count)
    tid = triples.add(cid, rid, eid)
    triples.add(cid, rid, eid)
    assert_equal(1, triples.count)
    assert(triples.fetch.any? { |t| t[:id] == tid })
    assert_equal(0, triples.fetch(id: tid)[0][:plans].count)
    triples.fetch.each { |t| triples.delete(t[:id]) }
  end

  def test_fetches_with_plans
    login = "sarah#{rand(99_999)}"
    project = Rsk::Projects.new(test_pgsql, login).add("test#{rand(99_999)}")
    cid = Rsk::Causes.new(test_pgsql, project).add('we have data')
    rid = Rsk::Risks.new(test_pgsql, project).add('we may lose it')
    eid = Rsk::Effects.new(test_pgsql, project).add('business will stop NOW')
    triples = Rsk::Triples.new(test_pgsql, project)
    tid = triples.add(cid, rid, eid)
    assert_equal(1, triples.fetch(query: '+alone').count)
    assert_equal(1, triples.fetch(query: "+#{cid}").count)
    assert_equal(1, triples.fetch(query: "+#{rid}").count)
    assert_equal(1, triples.fetch(query: "+#{eid}").count)
    plans = Rsk::Plans.new(test_pgsql, project)
    plans.add(rid, 'we\'ll do "it"')
    plans.add(eid, 'and this "one" too SUPER')
    assert_equal(2, triples.fetch(id: tid)[0][:plans].count)
    assert_equal(1, triples.fetch(query: 'super').count)
    assert_equal(1, triples.fetch(query: 'now').count)
    assert_equal(0, triples.fetch(query: 'something-else').count)
    assert_equal(1, triples.fetch.count)
  end
end
