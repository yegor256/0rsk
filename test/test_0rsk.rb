# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../0rsk'
require_relative '../objects/rsk'
require_relative '../objects/projects'
require_relative '../objects/causes'
require_relative '../objects/risks'
require_relative '../objects/effects'
require_relative '../objects/triples'

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
      assert_predicate(last_response, :ok?, last_response.body)
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

  def test_deletes_ranked
    name = "deleter#{rand(99_999)}"
    pid = login(name)
    cid = Rsk::Causes.new(test_pgsql, pid).add('test cause')
    rid = Rsk::Risks.new(test_pgsql, pid).add('test risk')
    eid = Rsk::Effects.new(test_pgsql, pid).add('test effect')
    triples = Rsk::Triples.new(test_pgsql, pid)
    tid = triples.add(cid, rid, eid)
    get("/ranked/delete?id=#{tid}")
    assert_equal(302, last_response.status, last_response.body)
    follow_redirect!
    assert_equal(200, last_response.status, last_response.body)
    assert_includes(last_response.body, 'deleted')
  end

  private

  def login(name)
    set_cookie("glogin=#{name}")
    projects = Rsk::Projects.new(test_pgsql, name)
    pid = projects.add('test')
    set_cookie("0rsk-project=#{pid}")
    pid
  end
end
