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

require 'minitest/autorun'
require 'rack/test'
require_relative 'test__helper'
require_relative '../objects/rsk'
require_relative '../objects/causes'
require_relative '../objects/projects'

# Test of Causes.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2020 Yegor Bugayenko
# License:: MIT
class Rsk::CausesTest < Minitest::Test
  def test_adds_and_fetches
    pid = Rsk::Projects.new(test_pgsql, "tim#{rand(99_999)}").add("t#{rand(99_999)}")
    causes = Rsk::Causes.new(test_pgsql, pid)
    text = 'we use Ruby'
    assert_equal(0, causes.count)
    cid = causes.add(text)
    assert(cid.positive?)
    assert_equal(1, causes.count)
    assert(causes.fetch.any? { |c| c[:id] == cid })
    assert(causes.fetch.any? { |c| c[:text] == text })
  end

  def test_fetch_emojis
    pid = Rsk::Projects.new(test_pgsql, "tim#{rand(99_999)}").add("t#{rand(99_999)}")
    causes = Rsk::Causes.new(test_pgsql, pid)
    cid = causes.add('some cause')
    causes.get(cid).emoji = '💰'
    assert(causes.emojis.count > 1)
  end
end
