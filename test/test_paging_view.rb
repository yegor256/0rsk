# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'rack/test'
require 'securerandom'
require_relative 'test__helper'

require_relative '../0rsk'

class Rsk::PagingViewTest < TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_hides_the_next_link_on_the_last_page
    login = "u#{SecureRandom.hex(8)}"
    project = Rsk::Projects.new(test_pgsql, login).add("p#{SecureRandom.hex(8)}")
    causes = Rsk::Causes.new(test_pgsql, project)
    4.times { causes.add("cause #{SecureRandom.hex(8)}") }
    set_cookie("glogin=#{login}")
    set_cookie("0rsk-project=#{project}")
    get('/causes?limit=2&offset=2')
    assert_equal(200, last_response.status, last_response.body)
    assert_empty(nexts, "the last page must offer no Next: #{last_response.body}")
    get('/causes?limit=2&offset=0')
    refute_empty(nexts, "the first page must offer Next: #{last_response.body}")
  end

  private

  def nexts
    Nokogiri::HTML.parse(last_response.body).xpath("//a[normalize-space(text())='Next']")
  end
end
