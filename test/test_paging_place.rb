# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'rack/test'
require 'securerandom'
require_relative 'test__helper'

require_relative '../0rsk'

class Rsk::PagingPlaceTest < TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_puts_the_paging_after_the_table
    login = "u#{SecureRandom.hex(8)}"
    project = Rsk::Projects.new(test_pgsql, login).add("p#{SecureRandom.hex(8)}")
    causes = Rsk::Causes.new(test_pgsql, project)
    4.times { causes.add("cause #{SecureRandom.hex(8)}") }
    set_cookie("glogin=#{login}")
    set_cookie("0rsk-project=#{project}")
    get('/causes?limit=2&offset=2')
    assert_equal(200, last_response.status, last_response.body)
    html = Nokogiri::HTML.parse(last_response.body)
    refute_empty(html.xpath('//table'), last_response.body)
    paging = html.xpath("//p[contains(@class,'small')][.//a[normalize-space(text())='Previous']]").first
    refute_nil(paging, "the paging must be there: #{last_response.body}")
    refute_empty(
      paging.xpath('preceding::table'),
      "the paging must come after the table, not before it: #{last_response.body}"
    )
  end
end
