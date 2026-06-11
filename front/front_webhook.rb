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
  secret = ENV['GITHUB_WEBHOOK_SECRET'] || ''
  if secret != '' && signature
    expected = "sha256=#{OpenSSL::HMAC.hexdigest('sha256', secret, body)}"
    unless Rack::Utils.secure_compare(expected, signature)
      settings.log.warn('GitHub webhook HMAC verification failed')
      halt 401, 'HMAC verification failed'
    end
  elsif secret != ''
    settings.log.warn('GitHub webhook missing X-Hub-Signature-256 header')
    halt 401, 'Missing signature header'
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
  tasks.done(rows[0]['id'].to_i)
  settings.log.info("Task ##{rows[0]['id']} closed by GitHub issue #{repo}##{issue}")
  200
end
