# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'rack/test'
require 'securerandom'
require_relative 'test__helper'

require_relative '../0rsk'
require_relative '../objects/triples'

class Rsk::TripleAtomicTest < TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_keeps_the_texts_when_a_number_is_refused
    login = "u#{SecureRandom.hex(8)}"
    project = Rsk::Projects.new(test_pgsql, login).add("p#{SecureRandom.hex(8)}")
    text = "cause #{SecureRandom.hex(8)}"
    causes = Rsk::Causes.new(test_pgsql, project)
    cause = causes.add(text)
    set_cookie("glogin=#{login}")
    set_cookie("0rsk-project=#{project}")
    post(
      '/triple/save',
      "ctext=HACKED&rtext=r&etext=e&cid=#{cause}" \
      "&rid=#{Rsk::Risks.new(test_pgsql, project).add("risk #{SecureRandom.hex(8)}")}" \
      "&eid=#{Rsk::Effects.new(test_pgsql, project).add("effect #{SecureRandom.hex(8)}")}" \
      '&emoji=x&probability=not-a-number&impact=5'
    )
    assert_equal(302, last_response.status, last_response.body)
    assert_equal(text, causes.get(cause).text, 'the text must not change')
  end
end
