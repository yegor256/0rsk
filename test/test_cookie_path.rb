# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'rack/test'
require 'securerandom'
require_relative 'test__helper'

require_relative '../0rsk'

class Rsk::CookiePathTest < TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_scopes_every_cookie_to_the_whole_site
    login = "u#{SecureRandom.hex(8)}"
    set_cookie("glogin=#{login}")
    post("/projects/select?id=#{Rsk::Projects.new(test_pgsql, login).add("p#{SecureRandom.hex(8)}")}")
    assert_includes([302, 303], last_response.status, last_response.body)
    cookies = Array(last_response.headers['set-cookie']).flat_map { |h| h.split("\n") }
    refute_empty(cookies, last_response.headers.to_s)
    cookies.each do |cookie|
      assert_includes(cookie.downcase, 'path=/', "a cookie without a path is scoped to the route: #{cookie}")
    end
  end
end
