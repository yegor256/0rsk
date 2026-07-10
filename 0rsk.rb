# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

$stdout.sync = true

require 'glogin'
require 'glogin/codec'
require 'haml'
require 'iri'
require 'json'
require 'loog'
require 'pgtk'
require 'pgtk/pool'
require 'relative_time'
require 'sentry-ruby'
require 'sinatra'
require 'telebot'
require 'time'
require 'yaml'
require_relative 'objects/urror'
require_relative 'version'

if ENV['RACK_ENV'] != 'test'
  require 'rack/ssl'
  use Rack::SSL
end

configure do
  set :haml, format: :xhtml
  config = { 'github' => { 'client_id' => '?', 'client_secret' => '?', 'encryption_secret' => '' }, 'sentry' => '' }
  cfg = File.join(File.dirname(__FILE__), 'config.yml')
  if File.exist?(cfg)
    loaded = YAML.safe_load(File.open(cfg))
    config.merge!(loaded) if loaded.is_a?(Hash)
  end
  if config['sentry'] && !config['sentry'].empty?
    Sentry.init do |c|
      c.dsn = config['sentry']
      c.release = Rsk::VERSION
    end
  end
  set :bind, '0.0.0.0'
  set :show_exceptions, false
  set :raise_errors, false
  set :dump_errors, false
  set :config, config
  set :logging, true
  set :log, Loog::REGULAR
  set :rate_limits, []
  set :server_settings, timeout: 25
  set :glogin, GLogin::Auth.new(
    config['github']['client_id'],
    config['github']['client_secret'],
    'https://www.0rsk.com/github-callback'
  )
  if File.exist?('target/pgsql-config.yml')
    set :pgsql, Pgtk::Pool.new(Pgtk::Wire::Yaml.new(File.join(__dir__, 'target/pgsql-config.yml')), log: settings.log)
  else
    set :pgsql, Pgtk::Pool.new(Pgtk::Wire::Env.new('DATABASE_URL'), log: settings.log)
  end
  settings.pgsql.start!
end

get '/' do
  flash('/ranked') if @locals[:user]
  haml :index, layout: :layout, locals: merged(title: '/')
end

get '/ranked' do
  offset = [Integer(params[:offset] || '0'), 0].max
  limit = Integer(params[:limit] || '10')
  query = params[:q] || ''
  haml :ranked, layout: :layout, locals: merged(
    title: '/ranked',
    query: query,
    limit: limit,
    offset: offset,
    total: triples.count(query: query),
    triples: triples.fetch(query: query, offset: offset, limit: limit),
    alone: triples.fetch(query: '+alone', limit: 1)
  )
end

get '/ranked/delete' do
  id = params[:id]
  triples.delete(id)
  flash('/ranked', "The ranked triple ##{id} deleted")
end

post '/ranked/delete' do
  id = params[:id]
  triples.delete(id)
  flash('/ranked', "The ranked triple ##{id} deleted")
end

get '/projects' do
  haml :projects, layout: :layout, locals: merged(title: '/projects', projects: projects.fetch)
end

get '/projects/select' do
  pid = params[:id]
  response.set_cookie('0rsk-project', pid)
  flash('/ranked', "Project ##{pid} selected")
end

post '/projects/create' do
  title = params[:title]
  pid = projects.add(title)
  flash("/projects/select?id=#{pid}", "A new project ##{pid} selected")
end

get '/projects/delete' do
  pid = params[:id]
  projects.delete(pid)
  flash('/projects', "The project ##{pid} has been deleted")
end

post '/projects/delete' do
  pid = params[:id]
  projects.delete(pid)
  flash('/projects', "The project ##{pid} has been deleted")
end

get '/project/{id}' do
  pid = params[:id]
  raise Rsk::Urror, "Project ##{pid} not found" unless projects.exists?(pid)
  haml :project, layout: :layout, locals: merged(title: "##{pid}", pid: pid, trackers: trackers(pid: pid).fetch)
end

post '/project/{id}/tracker/add' do
  pid = params[:id]
  raise Rsk::Urror, "Project ##{pid} not found" unless projects.exists?(pid)
  trackers(pid: pid).add(params[:repo], params[:token])
  flash("/project/#{pid}", 'Tracker added')
end

post '/project/{id}/tracker/delete' do
  pid = params[:id]
  tid = Integer(params[:tid], 10)
  raise Rsk::Urror, "Project ##{pid} not found" unless projects.exists?(pid)
  trackers(pid: pid).delete(tid)
  flash("/project/#{pid}", 'Tracker removed')
end

get '/responses' do
  id = Integer(params[:id])
  triple = triples.fetch(id: id, limit: 1)[0]
  raise(Rsk::Urror, "Triple ##{id} not found") if triple.nil?
  haml :responses, layout: :layout, locals: merged(
    title: '/triple',
    triple: triple,
    plans: plans.fetch(query: id, limit: 100)
  )
end

post '/responses/add' do
  id = Integer(params[:id])
  part = Integer(params[:strategy])
  pid = plans.add(part, params[:plan])
  plans.get(pid, part).reschedule(params[:schedule].strip)
  flash("/responses?id=#{id}", "Thanks, plan ##{pid}/#{part} added to the triple ##{id}")
end

get '/responses/detach' do
  tid = Integer(params[:tid])
  id = Integer(params[:id])
  part = Integer(params[:part])
  plans.get(id, part).detach
  flash("/responses?id=#{tid}", "Thanks, plan ##{id} detached from the triple ##{tid}")
end

get '/causes' do
  offset = [Integer(params[:offset] || '0'), 0].max
  limit = Integer(params[:limit] || '25')
  query = params[:q] || ''
  haml :causes, layout: :layout, locals: merged(
    title: '/causes',
    query: query,
    offset: offset,
    limit: limit,
    emojis: causes.emojis,
    total: causes.count(query: query),
    causes: causes.fetch(query: query, offset: offset, limit: limit)
  )
end

get '/risks' do
  offset = [Integer(params[:offset] || '0'), 0].max
  limit = Integer(params[:limit] || '25')
  query = params[:q] || ''
  haml :risks, layout: :layout, locals: merged(
    title: '/risks',
    query: query,
    offset: offset,
    limit: limit,
    total: risks.count(query: query),
    risks: risks.fetch(query: query, offset: offset, limit: limit)
  )
end

get '/effects' do
  offset = [Integer(params[:offset] || '0'), 0].max
  limit = Integer(params[:limit] || '25')
  query = params[:q] || ''
  haml :effects, layout: :layout, locals: merged(
    title: '/effects',
    query: query,
    offset: offset,
    limit: limit,
    total: effects.count(query: query),
    effects: effects.fetch(query: query, offset: offset, limit: limit)
  )
end

get '/plans' do
  offset = [Integer(params[:offset] || '0'), 0].max
  limit = Integer(params[:limit] || '25')
  query = params[:q] || ''
  haml :plans, layout: :layout, locals: merged(
    title: '/plans',
    query: query,
    offset: offset,
    limit: limit,
    total: plans.count(query: query),
    plans: plans.fetch(query: query, offset: offset, limit: limit)
  )
end

get '/terms' do
  haml :terms, layout: :layout, locals: merged(title: '/terms')
end

module Rsk::App
  def identity
    redirect('/') unless @locals[:user]
    @locals[:user]['id'].downcase
  end

  def pid
    id = request.cookies['0rsk-project']
    flash('/projects', 'Pick up a project to work with, or create a new one') unless id
    unless projects.exists?(id)
      response.delete_cookie('0rsk-project')
      flash('/projects', 'Pick up a new project')
    end
    id
  end

  def users
    require_relative('objects/users')
    @users ||= Rsk::Users.new(settings.pgsql)
  end

  def projects(login: identity)
    require_relative('objects/projects')
    Rsk::Projects.new(settings.pgsql, login)
  end

  def triples(project: pid)
    require_relative('objects/triples')
    Rsk::Triples.new(settings.pgsql, project)
  end

  def causes(project: pid)
    require_relative('objects/causes')
    Rsk::Causes.new(settings.pgsql, project)
  end

  def risks(project: pid)
    require_relative('objects/risks')
    Rsk::Risks.new(settings.pgsql, project)
  end

  def effects(project: pid)
    require_relative('objects/effects')
    Rsk::Effects.new(settings.pgsql, project)
  end

  def plans(project: pid)
    require_relative('objects/plans')
    Rsk::Plans.new(settings.pgsql, project)
  end

  def trackers(pid:)
    require_relative('objects/trackers')
    Rsk::Trackers.new(settings.pgsql, pid)
  end

  def iri
    Iri.new(request.url)
  end
end
Object.include(Rsk::App)

require_relative 'front/front_helpers'
require_relative 'front/front_login'
require_relative 'front/front_misc'
require_relative 'front/front_tasks'
require_relative 'front/front_telegram'
require_relative 'front/front_triple'
