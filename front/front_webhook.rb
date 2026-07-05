# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../objects/tasks'
require 'json'
require 'openssl'

post '/webhook/github' do
  request.body.rewind
  body = request.body.read
  signature = request.env['HTTP_X_HUB_SIGNATURE_256']
  secret = ENV.fetch('GITHUB_WEBHOOK_SECRET', nil)
  if secret.nil? || secret.empty?
    settings.log.warn('GITHUB_WEBHOOK_SECRET is not configured — webhook endpoint disabled')
    halt 503, 'Webhook secret not configured'
  end
  if signature.nil? || signature.empty?
    settings.log.warn('GitHub webhook missing X-Hub-Signature-256 header')
    halt 401, 'Missing signature header'
  end
  expected = "sha256=#{OpenSSL::HMAC.hexdigest('sha256', secret, body)}"
  unless Rack::Utils.secure_compare(expected, signature)
    settings.log.warn('GitHub webhook HMAC verification failed')
    halt 401, 'HMAC verification failed'
  end
  payload = JSON.parse(body)
  return 200 unless payload['action'] == 'closed' && payload['issue']
  repo = payload['repository']['full_name']
  issue = payload['issue']['number']
  rows = settings.pgsql.exec(
    "SELECT task.id, project.login FROM task
      JOIN plan ON plan.id = task.plan
      JOIN part ON plan.id = part.id
      JOIN project ON part.project = project.id
      WHERE (task.tracker_data::json)->>'repo' = $1
      AND (task.tracker_data::json)->>'issue' = $2",
    [repo, issue.to_s]
  )
  return 200 if rows.empty?
  tasks = Rsk::Tasks.new(settings.pgsql, rows[0]['login'])
  tasks.done(Integer(rows[0]['id'], 10))
  settings.log.info("Task ##{rows[0]['id']} closed by GitHub issue #{repo}##{issue}")
  200
end
