# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'rack/test'
require 'securerandom'
require_relative 'test__helper'

require_relative '../0rsk'
require_relative '../objects/triples'

class Rsk::TriplePageTest < TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_shows_the_probability_the_triple_has
    login = "u#{SecureRandom.hex(8)}"
    project = Rsk::Projects.new(test_pgsql, login).add("p#{SecureRandom.hex(8)}")
    risk = Rsk::Risks.new(test_pgsql, project).add("risk #{SecureRandom.hex(8)}")
    Rsk::Risks.new(test_pgsql, project).get(risk).weigh(8)
    set_cookie("glogin=#{login}")
    set_cookie("0rsk-project=#{project}")
    get(
      "/triple?id=#{Rsk::Triples.new(test_pgsql, project).add(
        Rsk::Causes.new(test_pgsql, project).add("cause #{SecureRandom.hex(8)}"),
        risk,
        Rsk::Effects.new(test_pgsql, project).add("effect #{SecureRandom.hex(8)}")
      )}"
    )
    assert_equal(200, last_response.status, last_response.body)
    html = Nokogiri::HTML.parse(last_response.body)
    assert_equal(
      ['8'],
      html.xpath("//select[@id='probability']/option[@selected]").map { |o| o['value'] },
      "exactly one option must be selected: #{last_response.body}"
    )
  end
end
