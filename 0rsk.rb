# frozen_string_literal: true

# Copyright (c) 2019 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

STDOUT.sync = true

require 'glogin'
require 'glogin/codec'
require 'haml'
require 'iri'
require 'json'
require 'pgtk'
require 'pgtk/pool'
require 'raven'
require 'relative_time'
require 'sinatra'
require 'sinatra/cookies'
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
    Raven.configure do |c|
      c.dsn = config['sentry']
      c.release = Rsk::VERSION
    end
  end
  set :show_exceptions, false
  set :raise_errors, false
  set :dump_errors, false
  set :config, config
  set :logging, true
  set :server_settings, timeout: 25
  set :glogin, GLogin::Auth.new(
    config['github']['client_id'],
    config['github']['client_secret'],
    'https://www.0rsk.com/github-callback'
  )
  if File.exist?('target/pgsql-config.yml')
    cfg = YAML.load_file('target/pgsql-config.yml')
    set :pgsql, Pgtk::Pool.new(
      host: cfg['pgsql']['host'],
      port: cfg['pgsql']['port'],
      dbname: cfg['pgsql']['dbname'],
      user: cfg['pgsql']['user'],
      password: cfg['pgsql']['password'],
      log: nil
    )
  else
    uri = URI(ENV['DATABASE_URL'])
    set :pgsql, Pgtk::Pool.new(
      host: uri.host,
      port: uri.port,
      dbname: uri.path[1..-1],
      user: uri.userinfo.split(':')[0],
      password: uri.userinfo.split(':')[1],
      log: nil
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
  cookies['0rsk-project'] = pid
  flash('/ranked', "Project ##{pid} selected")
end

post '/projects/create' do
  title = params[:title]
  pid = projects.add(title)
  flash("/projects/select?id=#{pid}", "A new project ##{pid} selected")
end

get '/projects/{id}' do
  pid = params[:id]
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

def current_user
  redirect '/' unless @locals[:user]
  @locals[:user][:login].downcase
end

def current_project
  pid = cookies['0rsk-project']
  flash('/projects', 'Pick up a project to work with, or create a new one') unless pid
  unless projects.exists?(pid)
    cookies.delete('0rsk-project')
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

require_relative 'front/front_tasks.rb'
require_relative 'front/front_telegram.rb'
require_relative 'front/front_triple.rb'
require_relative 'front/front_misc.rb'
require_relative 'front/front_login.rb'
require_relative 'front/front_helpers.rb'
