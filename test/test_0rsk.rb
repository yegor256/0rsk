# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'json'
require 'openssl'

require_relative 'test__helper'

require_relative '../0rsk'
require_relative '../objects/causes'
require_relative '../objects/effects'
require_relative '../objects/plans'
require_relative '../objects/projects'
require_relative '../objects/risks'
require_relative '../objects/rsk'
require_relative '../objects/tasks'
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

  def test_webhook_ignores_non_closed
    login("wh_ign#{SecureRandom.hex(8)}")
    payload = { action: 'opened', issue: { number: 1 }, repository: { full_name: 'owner/repo' } }.to_json
    ENV['GITHUB_WEBHOOK_SECRET'] = 'test'
    header('X-Hub-Signature-256', "sha256=#{OpenSSL::HMAC.hexdigest('sha256', 'test', payload)}")
    post('/webhook/github', payload, { 'CONTENT_TYPE' => 'application/json' })
    assert_equal(200, last_response.status)
  ensure
    ENV.delete('GITHUB_WEBHOOK_SECRET')
  end

  def test_webhook_closes_task
    ref = SecureRandom.hex(8)
    the_login = "wh_close_#{ref}"
    pid = login(the_login)
    rid = Rsk::Risks.new(test_pgsql, pid).add("risk #{ref}")
    Rsk::Triples.new(test_pgsql, pid).add(
      Rsk::Causes.new(test_pgsql, pid).add("cause #{ref}"), rid,
      Rsk::Effects.new(test_pgsql, pid).add("effect #{ref}")
    )
    Rsk::Plans.new(test_pgsql, pid).get(
      Rsk::Plans.new(test_pgsql, pid).add(rid, "plan #{ref}"),
      rid
    ).reschedule('01-01-2000')
    Rsk::Tasks.new(test_pgsql, the_login).create
    task = Rsk::Tasks.new(test_pgsql, the_login).fetch.first
    refute_nil(task, 'No task was created')
    test_pgsql.exec(
      'UPDATE task SET tracker_data = $1 WHERE id = $2',
      [JSON.generate({ repo: 'owner/repo', issue: 42 }), task[:id]]
    )
    payload = { action: 'closed', issue: { number: 42 }, repository: { full_name: 'owner/repo' } }.to_json
    ENV['GITHUB_WEBHOOK_SECRET'] = 'test'
    header('X-Hub-Signature-256', "sha256=#{OpenSSL::HMAC.hexdigest('sha256', 'test', payload)}")
    post('/webhook/github', payload, { 'CONTENT_TYPE' => 'application/json' })
    assert_equal(200, last_response.status)
    refute_includes(Rsk::Tasks.new(test_pgsql, the_login).fetch.map { |t| t[:id] }, task[:id])
  ensure
    ENV.delete('GITHUB_WEBHOOK_SECRET')
  end

  def test_webhook_hmac_missing_rejects
    ENV['GITHUB_WEBHOOK_SECRET'] = 'secret'
    post('/webhook/github', '{}', { 'CONTENT_TYPE' => 'application/json' })
    assert_equal(401, last_response.status)
  ensure
    ENV.delete('GITHUB_WEBHOOK_SECRET')
  end

  def test_webhook_hmac_invalid_rejects
    ENV['GITHUB_WEBHOOK_SECRET'] = 'real'
    header('X-Hub-Signature-256', "sha256=#{'a' * 64}")
    post('/webhook/github', '{}', { 'CONTENT_TYPE' => 'application/json' })
    assert_equal(401, last_response.status)
  ensure
    ENV.delete('GITHUB_WEBHOOK_SECRET')
  end

  def test_webhook_no_secret_rejects
    ENV.delete('GITHUB_WEBHOOK_SECRET')
    post('/webhook/github', '{}', { 'CONTENT_TYPE' => 'application/json' })
    assert_equal(503, last_response.status)
  end

  private

  def login(name)
    set_cookie("glogin=#{name}")
    pid = Rsk::Projects.new(test_pgsql, name).add('test')
    set_cookie("0rsk-project=#{pid}")
    pid
  end
end
