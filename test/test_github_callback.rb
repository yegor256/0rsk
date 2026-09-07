# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'rack/test'
require_relative 'test__helper'

require_relative '../0rsk'

class Rsk::GithubCallbackTest < TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_answers_a_refused_code_with_a_message
    refusing = Object.new
    def refusing.user(_code)
      raise 'HTTP error #401 with code abc: {"error":"bad_verification_code"}'
    end

    def refusing.login_uri
      'https://github.com/login/oauth/authorize'
    end
    origin = Sinatra::Application.settings.glogin
    begin
      Sinatra::Application.set(:glogin, refusing)
      get('/github-callback?code=already-used')
      assert_equal(302, last_response.status, last_response.body)
      refute_includes(last_response.body, '<pre', last_response.body)
      assert_includes(last_response.headers['Set-Cookie'].to_s, 'flash_msg', last_response.headers.to_s)
    ensure
      Sinatra::Application.set(:glogin, origin)
    end
  end
end
