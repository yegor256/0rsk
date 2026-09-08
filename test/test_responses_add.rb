# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'rack/test'
require 'securerandom'
require_relative 'test__helper'

require_relative '../0rsk'
require_relative '../objects/plans'
require_relative '../objects/triples'

class Rsk::ResponsesAddTest < TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_adds_no_plan_when_the_schedule_is_refused
    login = "u#{SecureRandom.hex(8)}"
    project = Rsk::Projects.new(test_pgsql, login).add("p#{SecureRandom.hex(8)}")
    risk = Rsk::Risks.new(test_pgsql, project).add("risk #{SecureRandom.hex(8)}")
    set_cookie("glogin=#{login}")
    set_cookie("0rsk-project=#{project}")
    post(
      "/responses/add?id=#{Rsk::Triples.new(test_pgsql, project).add(
        Rsk::Causes.new(test_pgsql, project).add("cause #{SecureRandom.hex(8)}"),
        risk,
        Rsk::Effects.new(test_pgsql, project).add("effect #{SecureRandom.hex(8)}")
      )}&strategy=#{risk}&plan=my+plan&schedule=nonsense"
    )
    assert_equal(302, last_response.status, last_response.body)
    assert_equal(0, Rsk::Plans.new(test_pgsql, project).count(query: ''), 'no plan may be left behind')
  end

  def test_answers_a_missing_schedule_with_a_message
    login = "u#{SecureRandom.hex(8)}"
    set_cookie("glogin=#{login}")
    set_cookie("0rsk-project=#{Rsk::Projects.new(test_pgsql, login).add("p#{SecureRandom.hex(8)}")}")
    post('/responses/add?id=1&strategy=1&plan=x')
    assert_equal(302, last_response.status, last_response.body)
    refute_includes(last_response.body, '<pre', last_response.body)
  end
end
