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
require_relative '../objects/risks'
require_relative '../objects/projects'

# Test of Risk.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2023 Yegor Bugayenko
# License:: MIT
class Rsk::RiskTest < Minitest::Test
  def test_modifies_text
    pid = Rsk::Projects.new(test_pgsql, 'jeff32').add('test')
    before = 'text first'
    after = 'another text to set'
    risks = Rsk::Risks.new(test_pgsql, pid)
    risk = risks.get(risks.add(before))
    assert_equal(before, risk.text)
    risk.text = after
    risk.text = after
    assert_equal(after, risk.text)
  end

  def test_modifies_probability
    pid = Rsk::Projects.new(test_pgsql, 'jeff94').add('test')
    after = 9
    risks = Rsk::Risks.new(test_pgsql, pid)
    risk = risks.get(risks.add('some risk'))
    risk.probability = after
    risk.probability = after
    assert_equal(after, risk.probability)
  end
end
