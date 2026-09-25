# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'rack/test'
require 'securerandom'
require_relative 'test__helper'

require_relative '../0rsk'

class Rsk::TasksCountTest < TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_serves_the_plain_pages_without_counting
    login = "u#{SecureRandom.hex(8)}"
    Rsk::Projects.new(test_pgsql, login).add("p#{SecureRandom.hex(8)}")
    set_cookie("glogin=#{login}")
    ['/version', '/robots.txt'].each do |uri|
      get(uri)
      assert_equal(200, last_response.status, "#{uri}: #{last_response.body}")
    end
  end

  def test_shows_the_count_in_the_favicon
    login = "u#{SecureRandom.hex(8)}"
    Rsk::Projects.new(test_pgsql, login).add("p#{SecureRandom.hex(8)}")
    set_cookie("glogin=#{login}")
    get('/favicon.svg')
    assert_equal(200, last_response.status, last_response.body)
    assert_includes(last_response.body, '<svg', last_response.body)
  end
end
