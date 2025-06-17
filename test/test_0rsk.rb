# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../0rsk'
require_relative '../objects/rsk'
require_relative '../objects/projects'

module Rack
  module Test
    class Session
      def default_env
        { 'REMOTE_ADDR' => '127.0.0.1', 'HTTPS' => 'on' }.merge(headers_for_env)
      end
    end
  end
end

class Rsk::AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_renders_pages
    pages = [
      '/version',
      '/robots.txt',
      '/',
      '/js/triple.js',
      '/js/responses.js',
      '/terms'
    ]
    pages.each do |p|
      get(p)
      assert_page_response_status url: p, reason_keyword: :ok
    end
  end

  def test_not_found
    ['/unknown_path', '/js/x/y/z/not-found.js', '/css/a/b/c/not-found.css'].each do |p|
      get(p)
      assert_equal(404, last_response.status, last_response.body)
      assert_equal('text/html;charset=utf-8', last_response.content_type)
    end
  end

  def test_200_user_pages
    name = 'bill'
    login(name)
    pages = [
      '/projects',
      '/ranked',
      '/tasks',
      '/triple',
      '/risks',
      '/causes',
      '/effects',
      '/plans',
      '/causes.json',
      '/risks.json',
      '/effects.json',
      '/plans.json'
    ]
    pages.each do |p|
      get(p)
      assert_equal(200, last_response.status, "#{p} fails: #{last_response.body}")
    end
  end

  def test_add
    name = "jeff09#{rand(99_999)}"
    login(name)
    post(
      '/triple/save',
      [
        'ctext=test+cause',
        'rtext=test+risk',
        'probability=5',
        'emoji=A',
        'etext=test+effect',
        'impact=5',
        'cid=',
        'rid=',
        'eid='
      ].join('&')
    )
    assert_equal(302, last_response.status, last_response.body)
    get('/ranked')
    assert_equal(200, last_response.status, last_response.body)
  end

  private

  def login(name)
    set_cookie("glogin=#{name}")
    projects = Rsk::Projects.new(test_pgsql, name)
    pid = projects.add('test')
    set_cookie("0rsk-project=#{pid}")
  end

  def assert_page_response_status(url:, reason_keyword:)
    expected_code = Rack::Utils.status_code(reason_keyword)
    msg = <<~TEXT.delete("\n")
      Response status code of #{url} expected to be #{expected_code}
       #{reason_keyword.capitalize},
       but was #{last_response.status} #{Rack::Utils::HTTP_STATUS_CODES[last_response.status]}
    TEXT
    assert_equal expected_code, last_response.status, msg
  end
end
