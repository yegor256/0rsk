# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'rack/test'
require 'securerandom'
require_relative 'test__helper'

require_relative '../0rsk'

class Rsk::SecureCookieTest < TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_marks_the_project_cookie_secure_over_https
    login = "u#{SecureRandom.hex(8)}"
    set_cookie("glogin=#{login}")
    pid = Rsk::Projects.new(test_pgsql, login).add("p#{SecureRandom.hex(8)}")
    post('/projects/select', { id: pid }, 'HTTPS' => 'on')
    assert_equal(302, last_response.status, last_response.body)
    assert_includes(last_response.headers['set-cookie'].to_s, 'secure')
  end
end
