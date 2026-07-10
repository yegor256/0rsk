# frozen_string_literal: true

require 'json'
require 'timeout'

require_relative '../objects/daemon'
require_relative '../objects/pipeline'
# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../objects/postpone'
require_relative '../objects/tasks'
require_relative '../objects/tasktracker'
require_relative '../objects/trackers'

Rsk::Daemon.new(10).start do
  users.fetch.each do |login|
    tasks(login: login).create
    Rsk::Projects.new(settings.pgsql, login).fetch.each do |project|
      Rsk::Trackers.new(settings.pgsql, project[:id]).fetch(token: true).each do |trk|
        gh = Rsk::TaskTracker.new(trk[:repo], trk[:token])
        tasks(login: login).fetch(limit: 100).each do |task|
          next if task[:tracker_data] && JSON.parse(task[:tracker_data])['repo'] == trk[:repo]
          begin
            Timeout.timeout(15) do
              issue = gh.create(task)
              tasks(login: login).track(task[:id], trk[:repo], issue)
            end
          rescue Timeout::Error => e
            settings.log.error("GitHub push for task ##{task[:id]} timed out: #{e.message}")
          rescue StandardError => e
            settings.log.error("GitHub push failed for task ##{task[:id]}: #{e.message}")
          end
        end
      end
    end
  end
  @updated = Time.now
end

get '/tasks' do
  offset = [Integer(params[:offset] || '0'), 0].max
  limit = Integer(params[:limit] || '10')
  query = params[:q] || ''
  haml :tasks, layout: :layout, locals: merged(
    title: '/tasks',
    offset: offset,
    limit: limit,
    query: query,
    pipeline: pipeline.fetch.count,
    total: tasks.count(query: query),
    tasks: tasks.fetch(query: query, offset: offset, limit: limit),
    wired: telechats.wired?(identity),
    updated: @updated
  )
end

get '/tasks/done' do
  id = Integer(params[:id])
  tasks.done(id)
  flash('/tasks', "Thanks, task ##{id} was completed!")
end

get '/tasks/later' do
  id = Integer(params[:id])
  tasks.postpone(id, Rsk::Postpone.new(params[:period]).seconds)
  flash('/tasks', "Thanks, the task ##{id} was postponed")
end

get '/tasks/create' do
  tasks.create
  flash('/tasks', 'All necessary tasks were created, thanks!')
end

module Rsk::TasksFront
  def tasks(login: identity)
    Rsk::Tasks.new(settings.pgsql, login)
  end

  def pipeline(login: identity)
    Rsk::Pipeline.new(settings.pgsql, login)
  end
end
Object.include(Rsk::TasksFront)
