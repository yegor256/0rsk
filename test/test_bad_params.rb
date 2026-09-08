# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'rack/test'
require 'securerandom'
require_relative 'test__helper'

require_relative '../0rsk'

class Rsk::BadParamsTest < TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_shows_no_backtrace_for_a_bad_parameter
    login = "u#{SecureRandom.hex(8)}"
    set_cookie("glogin=#{login}")
    set_cookie("0rsk-project=#{Rsk::Projects.new(test_pgsql, login).add("p#{SecureRandom.hex(8)}")}")
    [
      '/ranked?limit=abc', '/ranked?offset[]=1', '/ranked?q[]=a', '/causes?limit=x',
      '/risks?offset=y', '/effects?limit=z', '/plans?limit=q', '/tasks?limit=w',
      '/triple?id=', '/responses'
    ].each do |uri|
      get(uri)
      refute_includes(last_response.body, '<pre', "#{uri} shows a backtrace: #{last_response.body[0, 200]}")
      refute_equal(503, last_response.status, "#{uri} answers 503")
    end
  end
end
