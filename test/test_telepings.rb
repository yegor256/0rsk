# frozen_string_literal: true

# Copyright (c) 2019-2024 Yegor Bugayenko
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
require_relative '../objects/tasks'
require_relative '../objects/plans'
require_relative '../objects/telechats'
require_relative '../objects/telepings'

# Test of Telepings.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2024 Yegor Bugayenko
# License:: MIT
class Rsk::TelepingsTest < Minitest::Test
  def test_fetches
    login = "judyT#{rand(99_999)}"
    test_tasks(login)
    telepings = Rsk::Telepings.new(test_pgsql)
    assert(!telepings.fresh(login).empty?)
    assert(telepings.required(login))
  end

  def test_adds
    login = "judyTA#{rand(99_999)}"
    tasks = test_tasks(login)
    telechats = Rsk::Telechats.new(test_pgsql)
    chat = rand(99_999)
    telechats.add(chat, login)
    telepings = Rsk::Telepings.new(test_pgsql)
    assert(!telepings.fresh(login).empty?)
    assert(telepings.required(login))
    tasks.fetch.each do |t|
      telepings.add(t[:id], chat)
      telepings.add(t[:id], chat)
    end
    assert(telepings.fresh(login).empty?)
    assert(!telepings.required(login))
  end

  private

  def test_tasks(login)
    project = Rsk::Projects.new(test_pgsql, login).add("test#{rand(9999)}")
    cid = Rsk::Causes.new(test_pgsql, project).add('we have data')
    rid = Rsk::Risks.new(test_pgsql, project).add('we may lose it')
    eid = Rsk::Effects.new(test_pgsql, project).add('business will stop')
    triples = Rsk::Triples.new(test_pgsql, project)
    triples.add(cid, rid, eid)
    plans = Rsk::Plans.new(test_pgsql, project)
    pid = plans.add(rid, 'solve it!')
    plans.get(pid, rid).schedule = (Time.now - (5 * 24 * 60 * 60)).strftime('%d-%m-%Y')
    tasks = Rsk::Tasks.new(test_pgsql, login)
    tasks.create
    assert(tasks.fetch.any? { |t| t[:plan] == pid })
    tasks
  end
end
