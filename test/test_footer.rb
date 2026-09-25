# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'rack/test'
require_relative 'test__helper'

require_relative '../0rsk'

class Rsk::FooterTest < TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_looks_up_the_address_the_server_sees
    get('/')
    assert_equal(200, last_response.status, last_response.body)
    links = Nokogiri::HTML.parse(last_response.body).xpath("//a[contains(@href,'iplocation.com')]")
    refute_empty(links, last_response.body)
    assert_includes(links.first['href'], 'ip=127.0.0.1', last_response.body)
  end
end
