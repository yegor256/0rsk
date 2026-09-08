# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'rack/test'
require 'securerandom'
require_relative 'test__helper'

require_relative '../0rsk'

class Rsk::TelegramPageTest < TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_tells_an_anonymous_visitor_to_log_in
    clear_cookies
    get('/telegram?token=whatever')
    assert_equal(302, last_response.status, last_response.body)
    assert_includes(last_response.headers['Set-Cookie'].to_s, 'Log', last_response.headers.to_s)
  end

  def test_shows_the_form_to_a_user
    set_cookie("glogin=u#{SecureRandom.hex(8)}")
    get('/telegram?token=whatever')
    assert_equal(200, last_response.status, last_response.body)
    assert_includes(last_response.body, 'Link', last_response.body)
  end
end
