# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'rack/test'
require 'securerandom'
require_relative 'test__helper'

require_relative '../0rsk'

class Rsk::TripleSaveTest < TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_refuses_a_form_field_that_is_not_a_text
    login = "u#{SecureRandom.hex(8)}"
    set_cookie("glogin=#{login}")
    set_cookie("0rsk-project=#{Rsk::Projects.new(test_pgsql, login).add("p#{SecureRandom.hex(8)}")}")
    post('/triple/save', 'ctext[]=x&rtext=r&etext=e&cid=&rid=&eid=&probability=1&impact=1')
    assert_equal(302, last_response.status, last_response.body)
    refute_includes(last_response.body, '<pre', last_response.body)
  end
end
