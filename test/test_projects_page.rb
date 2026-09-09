# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'rack/test'
require 'securerandom'
require_relative 'test__helper'

require_relative '../0rsk'

class Rsk::ProjectsPageTest < TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_puts_the_delete_button_inside_its_form
    login = "u#{SecureRandom.hex(8)}"
    set_cookie("glogin=#{login}")
    set_cookie("0rsk-project=#{Rsk::Projects.new(test_pgsql, login).add("p#{SecureRandom.hex(8)}")}")
    get('/projects')
    assert_equal(200, last_response.status, last_response.body)
    form = Nokogiri::HTML.parse(last_response.body).xpath("//form[contains(@action,'/projects/delete')]").first
    refute_nil(form, last_response.body)
    refute_empty(form.xpath('.//button'), "the Delete button must be inside its form: #{last_response.body}")
  end
end
