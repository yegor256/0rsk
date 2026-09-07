# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'rack/test'
require 'securerandom'
require_relative 'test__helper'
require_relative '../0rsk'
require_relative '../objects/plans'
require_relative '../objects/triples'

class Rsk::ResponsesTest < TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_renders_the_responses_page
    login = "u#{SecureRandom.hex(8)}"
    project = Rsk::Projects.new(test_pgsql, login).add("p#{SecureRandom.hex(8)}")
    risk = Rsk::Risks.new(test_pgsql, project).add("risk #{SecureRandom.hex(8)}")
    triple = Rsk::Triples.new(test_pgsql, project).add(
      Rsk::Causes.new(test_pgsql, project).add("cause #{SecureRandom.hex(8)}"),
      risk,
      Rsk::Effects.new(test_pgsql, project).add("effect #{SecureRandom.hex(8)}")
    )
    Rsk::Plans.new(test_pgsql, project).add(risk, "plan #{SecureRandom.hex(8)}")
    set_cookie("glogin=#{login}")
    set_cookie("0rsk-project=#{project}")
    ['/plans', '/tasks', "/responses?id=#{triple}"].each do |uri|
      get(uri)
      assert_equal(200, last_response.status, "#{uri} fails: #{last_response.body}")
    end
  end
end
