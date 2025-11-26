# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

$stdout.sync = true

require 'glogin'
require 'glogin/codec'
require 'haml'
require 'iri'
require 'loog'
require 'json'
require 'pgtk'
require 'pgtk/pool'
require 'sentry-ruby'
require 'relative_time'
require 'sinatra'
require 'telebot'
require 'time'
require 'yaml'
require_relative 'objects/urror'
require_relative 'version'

unless %w[test development].include?(ENV['RACK_ENV'])
  require 'rack/ssl'
  use Rack::SSL
end

configure do
  Haml::Options.defaults[:format] = :xhtml
  config = {
    'github' => {
      'client_id' => '?',
      'client_secret' => '?',
      'encryption_secret' => ''
    },
    'sentry' => ''
  }
  config = YAML.safe_load(File.open(File.join(File.dirname(__FILE__), 'config.yml'))) unless ENV['RACK_ENV'] == 'test'
  if ENV['RACK_ENV'] != 'test'
    Sentry.init do |c|
      c.dsn = config['sentry']
      c.release = Rsk::VERSION
    end
  end
  set :bind, '0.0.0.0'
  set :server, :thin
  set :show_exceptions, false
  set :raise_errors, false
  set :dump_errors, false
  set :config, config
  set :logging, true
  set :log, Loog::REGULAR
  set :server_settings, timeout: 25
  set :glogin, GLogin::Auth.new(
    config['github']['client_id'],
    config['github']['client_secret'],
    'https://www.0rsk.com/github-callback'
  )
  if File.exist?('target/pgsql-config.yml')
    set :pgsql, Pgtk::Pool.new(
      Pgtk::Wire::Yaml.new(File.join(__dir__, 'target/pgsql-config.yml')),
      log: settings.log
    )
  else
    set :pgsql, Pgtk::Pool.new(
      Pgtk::Wire::Env.new("#{Sinatra::Application.environment.upcase}_DATABASE_URL"),
      log: settings.log
    )
  end
  settings.pgsql.start(4)
end

get '/' do
  flash('/ranked') if @locals[:user]
  haml :index, layout: :layout, locals: merged(
    title: '/'
  )
end

get '/ranked' do
  offset = [(params[:offset] || '0').to_i, 0].max
  limit = (params[:limit] || '10').to_i
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

get '/projects' do
  haml :projects, layout: :layout, locals: merged(
    title: '/projects',
    projects: projects.fetch
  )
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

get '/project/{id}' do
  pid = params[:id]
  raise Rsk::Urror, "Project ##{pid} not found" unless projects.exists?(pid)
  haml :project, layout: :layout, locals: merged(
    title: "##{pid}",
    pid: pid
  )
end

get '/responses' do
  id = params[:id].to_i
  triple = triples.fetch(id: id, limit: 1)[0]
  raise Rsk::Urror, "Triple ##{id} not found" if triple.nil?
  haml :responses, layout: :layout, locals: merged(
    title: '/triple',
    triple: triple,
    plans: plans.fetch(query: id, limit: 100)
  )
end

post '/responses/add' do
  id = params[:id].to_i
  part = params[:strategy].to_i
  pid = plans.add(part, params[:plan])
  plans.get(pid, part).schedule = params[:schedule].strip
  flash("/responses?id=#{id}", "Thanks, plan ##{pid}/#{part} added to the triple ##{id}")
end

get '/responses/detach' do
  tid = params[:tid].to_i
  id = params[:id].to_i
  part = params[:part].to_i
  plans.get(id, part).detach
  flash("/responses?id=#{tid}", "Thanks, plan ##{id} detached from the triple ##{tid}")
end

get '/causes' do
  offset = [(params[:offset] || '0').to_i, 0].max
  limit = (params[:limit] || '25').to_i
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
  offset = [(params[:offset] || '0').to_i, 0].max
  limit = (params[:limit] || '25').to_i
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
  offset = [(params[:offset] || '0').to_i, 0].max
  limit = (params[:limit] || '25').to_i
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
  offset = [(params[:offset] || '0').to_i, 0].max
  limit = (params[:limit] || '25').to_i
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
  haml :terms, layout: :layout, locals: merged(
    title: '/terms'
  )
end

def current_user
  redirect '/' unless @locals[:user]
  @locals[:user]['id'].downcase
end

def current_project
  pid = request.cookies['0rsk-project']
  flash('/projects', 'Pick up a project to work with, or create a new one') unless pid
  unless projects.exists?(pid)
    response.delete_cookie('0rsk-project')
    flash('/projects', 'Pick up a new project')
  end
  pid
end

def users
  require_relative 'objects/users'
  @users ||= Rsk::Users.new(settings.pgsql)
end

def projects(login: current_user)
  require_relative 'objects/projects'
  Rsk::Projects.new(settings.pgsql, login)
end

def triples(project: current_project)
  require_relative 'objects/triples'
  Rsk::Triples.new(settings.pgsql, project)
end

def causes(project: current_project)
  require_relative 'objects/causes'
  Rsk::Causes.new(settings.pgsql, project)
end

def risks(project: current_project)
  require_relative 'objects/risks'
  Rsk::Risks.new(settings.pgsql, project)
end

def effects(project: current_project)
  require_relative 'objects/effects'
  Rsk::Effects.new(settings.pgsql, project)
end

def plans(project: current_project)
  require_relative 'objects/plans'
  Rsk::Plans.new(settings.pgsql, project)
end

def iri
  Iri.new(request.url)
end

require_relative 'front/front_tasks'
require_relative 'front/front_telegram'
require_relative 'front/front_triple'
require_relative 'front/front_misc'
require_relative 'front/front_login'
require_relative 'front/front_helpers'
