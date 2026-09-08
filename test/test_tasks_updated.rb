# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'rack/test'
require 'securerandom'
require_relative 'test__helper'

require_relative '../0rsk'

class Rsk::TasksUpdatedTest < TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_shows_the_moment_the_plans_were_checked
    login = "u#{SecureRandom.hex(8)}"
    set_cookie("glogin=#{login}")
    set_cookie("0rsk-project=#{Rsk::Projects.new(test_pgsql, login).add("p#{SecureRandom.hex(8)}")}")
    was = Sinatra::Application.settings.updated
    begin
      Sinatra::Application.set(:updated, Time.now - 300)
      get('/tasks')
      assert_equal(200, last_response.status, last_response.body)
      assert_includes(last_response.body, 'The last time plans were checked', last_response.body)
      assert_includes(last_response.body, 'ago', last_response.body)
    ensure
      Sinatra::Application.set(:updated, was)
    end
  end
end
