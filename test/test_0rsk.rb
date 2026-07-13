# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../0rsk'
require_relative '../objects/causes'
require_relative '../objects/effects'
require_relative '../objects/projects'
require_relative '../objects/risks'
require_relative '../objects/rsk'
require_relative '../objects/triples'

module Rack
  module Test
    class Session
      def defaults
        { 'REMOTE_ADDR' => '127.0.0.1', 'HTTPS' => 'on' }.merge(headers_for_env)
      end
      alias default_env defaults
    end
  end
end

class Rsk::AppTest < TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_renders_pages
    pages = ['/version', '/robots.txt', '/', '/js/triple.js', '/js/responses.js', '/terms']
    pages.each do |p|
      get(p)
      assert_status(url: p, reason_keyword: :ok)
    end
  end

  def test_not_found
    ['/unknown_path', '/js/x/y/z/not-found.js', '/css/a/b/c/not-found.css'].each do |p|
      get(p)
      assert_equal(404, last_response.status, last_response.body)
      assert_equal('text/html;charset=utf-8', last_response.content_type)
    end
  end

  def test_user_pages
    login('bill')
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
    login("jeff09#{rand(99_999)}")
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

  def test_logout
    login('bob')
    get('/logout')
    assert_equal(302, last_response.status, last_response.body)
    assert(last_response.location.end_with?('/'))
    cookie = last_response.headers['Set-Cookie']
    refute_nil(cookie, last_response.body)
    assert_includes(cookie.to_s, 'glogin=', last_response.body)
  end

  def test_deletes_ranked
    pid = login("deleter#{rand(99_999)}")
    get(
      "/ranked/delete?id=#{Rsk::Triples.new(test_pgsql, pid).add(
        Rsk::Causes.new(test_pgsql, pid).add('test cause'),
        Rsk::Risks.new(test_pgsql, pid).add('test risk'),
        Rsk::Effects.new(test_pgsql, pid).add('test effect')
      )}"
    )
    assert_equal(302, last_response.status, last_response.body)
    assert(last_response.location.end_with?('/ranked'))
    cookie = last_response.headers['Set-Cookie']
    refute_nil(cookie, last_response.body)
    assert_includes(cookie.to_s, 'deleted')
  end

  def test_deletes_project
    get("/projects/delete?id=#{login("deleter#{rand(99_999)}")}")
    assert_equal(302, last_response.status, last_response.body)
    assert(last_response.location.end_with?('/projects'))
    cookie = last_response.headers['Set-Cookie']
    refute_nil(cookie, last_response.body)
    assert_includes(cookie.to_s, 'deleted')
  end

  def test_telegram_listing_plain_text
    listing = Object.new.extend(Rsk::Telegram).listing(
      [
        {
          id: 42,
          triple: 7,
          positive: true,
          rank: 3,
          text: 'Fix "urgent" bug',
          title: 'Project',
          pid: 5,
          ctext: 'Cause',
          rtext: 'Risk',
          etext: 'Effect',
          schedule: 'today'
        }
      ]
    ).flatten.join(' ')
    assert_includes(listing, 'Fix "urgent" bug')
    refute_includes(listing, '"Fix \\"urgent\\" bug"')
  end

  private

  def login(name)
    set_cookie("glogin=#{name}")
    pid = Rsk::Projects.new(test_pgsql, name).add('test')
    set_cookie("0rsk-project=#{pid}")
    pid
  end

  def assert_status(url:, reason_keyword:)
    expected = Rack::Utils.status_code(reason_keyword)
    assert_equal(
      expected,
      last_response.status,
      "Response status of #{url} expected #{expected} #{reason_keyword}, got #{last_response.status} #{Rack::Utils::HTTP_STATUS_CODES[last_response.status]}"
    )
  end
end
