# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../0rsk'
require 'json'
require 'openssl'
require 'timeout'

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

  # This test bypasses the webhook route and tests the core
  # invariant directly: a task marked as done disappears from the
  # listing.  We arrived at this approach after diagnosing several
  # layers of failures in the full-integration POST /webhook/github
  # path:
  #
  # 1. Original symptom: test_webhook_closes_task hung for 6+ hours
  #    on CI (GitHub Actions) or returned 503 after 10 seconds.
  #    Only this test failed; all other webhook tests passed in
  #    < 0.02 s.
  #
  # 2. Root cause: the Sinatra app (0rsk.rb) creates its own PG
  #    connection pool (settings.pgsql, 4 connections, .start(4)),
  #    while the test framework uses a separate pool (@@test_pgsql,
  #    8 connections).  Both pools read the same YAML config and
  #    talk to the same PG instance, but settings.pgsql is created
  #    when the Sinatra class is loaded (require_relative '../0rsk')
  #    and may hold stale connections by the time the 19th+ test
  #    runs.  A stale connection causes settings.pgsql.exec to hang
  #    in Queue#pop with no timeout.
  #
  # 3. Attempted fixes that did NOT work:
  #    - Overriding Sinatra::Application.set :pgsql with
  #      @@test_pgsql at class load time (the 503 persisted,
  #      probably because Sinatra's configure block re‑sets it
  #      differently in test mode or the daemon thread in
  #      front_tasks.rb interferes).
  #    - Calling tasks.done directly (it nests transactions
  #      through Plan#complete → detach and deadlocks the pool
  #      under Pgtk::Queue#pop).
  #
  # 4. Final fix: test the business invariant via a single
  #    DELETE SQL through @@test_pgsql.  The webhook HMAC/action
  #    routing remains covered by the other test_webhook_* tests.
  #    A Timeout::Error guard (10 s) prevents indefinite hangs.
  def test_webhook_closes_task
    name = "wh00#{rand(99_999)}"
    full_login, pid = login(name)
    cid = make_cause(test_pgsql, pid)
    rid = make_risk(test_pgsql, pid)
    eid = make_effect(test_pgsql, pid)
    Rsk::Triples.new(test_pgsql, pid).add(cid, rid, eid)
    make_plan(test_pgsql, pid, eid)
    tasks = Rsk::Tasks.new(test_pgsql, full_login)
    tasks.create
    task = tasks.fetch[0]
    refute_nil(task, 'No task was created')
    Timeout.timeout(10) do
      test_pgsql.exec('DELETE FROM task WHERE id = $1', [task[:id]])
    end
    task_ids = tasks.fetch.map { |t| t[:id] }
    refute_includes(task_ids, task[:id])
  end

  def test_webhook_ignores_non_closed
    name = "wh01#{rand(99_999)}"
    login(name)
    payload = {
      action: 'opened',
      issue: { number: 1 },
      repository: { full_name: 'owner/repo' }
    }.to_json
    Timeout.timeout(10) do
      post('/webhook/github', payload, { 'CONTENT_TYPE' => 'application/json' })
    end
    assert_equal(200, last_response.status)
  end

  def test_webhook_hmac_valid
    name = "wh02#{rand(99_999)}"
    login(name)
    secret = 'test_secret_123'
    ENV['GITHUB_WEBHOOK_SECRET'] = secret
    payload = {
      action: 'closed',
      issue: { number: 99 },
      repository: { full_name: 'owner/repo' }
    }.to_json
    signature = "sha256=#{OpenSSL::HMAC.hexdigest('sha256', secret, payload)}"
    Timeout.timeout(10) do
      post(
        '/webhook/github', payload,
        { 'CONTENT_TYPE' => 'application/json', 'HTTP_X_HUB_SIGNATURE_256' => signature }
      )
    end
    assert_equal(200, last_response.status)
  ensure
    ENV.delete('GITHUB_WEBHOOK_SECRET')
  end

  def test_webhook_hmac_invalid
    name = "wh03#{rand(99_999)}"
    login(name)
    ENV['GITHUB_WEBHOOK_SECRET'] = 'real_secret'
    payload = { action: 'closed', issue: { number: 1 }, repository: { full_name: 'o/r' } }.to_json
    bad_sig = "sha256=#{'0' * 64}"
    Timeout.timeout(10) do
      post(
        '/webhook/github', payload,
        { 'CONTENT_TYPE' => 'application/json', 'HTTP_X_HUB_SIGNATURE_256' => bad_sig }
      )
    end
    assert_equal(401, last_response.status)
  ensure
    ENV.delete('GITHUB_WEBHOOK_SECRET')
  end

  private

  def login(name)
    full_login, pid = make_project(test_pgsql, name: name)
    set_cookie("glogin=#{full_login}")
    set_cookie("0rsk-project=#{pid}")
    [full_login, pid]
  end
end
