# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../objects/tasks'
require_relative '../objects/pipeline'
require_relative '../objects/daemon'
require_relative '../objects/trackers'
require_relative '../objects/tasktracker'

Rsk::Daemon.new(10).start do
  users.fetch.each do |login|
    tasks(login: login).create
    Rsk::Projects.new(settings.pgsql, login).fetch.each do |project|
      Rsk::Trackers.new(settings.pgsql, project[:id]).fetch.each do |trk|
        tasks(login: login).fetch(limit: 100).each do |task|
          next if task[:tracker_data]
          gh = Rsk::TaskTracker.new(trk[:repo], trk[:token])
          issue = gh.create(task)
          tasks(login: login).track(task[:id], trk[:repo], issue)
        rescue StandardError => e
          settings.log.error("GitHub push failed for task ##{task[:id]}: #{e.message}")
        end
      end
    end
  end
  @tasks_updated = Time.now
end

get '/tasks' do
  offset = [(params[:offset] || '0').to_i, 0].max
  limit = (params[:limit] || '10').to_i
  query = params[:q] || ''
  haml :tasks, layout: :layout, locals: merged(
    title: '/tasks',
    offset: offset,
    limit: limit,
    query: query,
    pipeline: pipeline.fetch.count,
    total: tasks.count(query: query),
    tasks: tasks.fetch(query: query, offset: offset, limit: limit),
    wired: telechats.wired?(current_user),
    updated: @tasks_updated
  )
end

get '/tasks/done' do
  id = params[:id].to_i
  tasks.done(id)
  flash('/tasks', "Thanks, task ##{id} was completed!")
end

get '/tasks/later' do
  id = params[:id].to_i
  seconds = 1
  seconds *= 7 * 24 * 60 * 60 if params[:period] == 'week'
  seconds *= 30 * 24 * 60 * 60 if params[:period] == 'month'
  seconds *= 3 * 30 * 24 * 60 * 60 if params[:period] == 'quarter'
  tasks.postpone(id, seconds)
  flash('/tasks', "Thanks, the task ##{id} was postponed")
end

get '/tasks/create' do
  tasks.create
  flash('/tasks', 'All necessary tasks were created, thanks!')
end

def tasks(login: current_user)
  Rsk::Tasks.new(settings.pgsql, login)
end

def pipeline(login: current_user)
  Rsk::Pipeline.new(settings.pgsql, login)
end
