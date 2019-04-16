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

require 'geocoder'
require 'glogin'
require 'glogin/codec'
require 'haml'
require 'json'
require 'pgtk'
require 'pgtk/pool'
require 'raven'
require 'sinatra'
require 'sinatra/cookies'
require 'time'
require 'yaml'
require_relative 'version'
require_relative 'objects/urror'

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
    'pgsql' => {
      'host' => 'localhost',
      'port' => 0,
      'user' => 'test',
      'dbname' => 'test',
      'password' => 'test'
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
  cfg = File.exist?('target/pgsql-config.yml') ? YAML.load_file('target/pgsql-config.yml') : config
  set :pgsql, Pgtk::Pool.new(
    host: cfg['pgsql']['host'],
    port: cfg['pgsql']['port'],
    dbname: cfg['pgsql']['dbname'],
    user: cfg['pgsql']['user'],
    password: cfg['pgsql']['password']
  ).start(4)
end

before '/*' do
  @locals = {
    ver: Rsk::VERSION,
    login_link: settings.glogin.login_uri,
    request_ip: request.ip
  }
  cookies[:glogin] = params[:glogin] if params[:glogin]
  if cookies[:glogin]
    begin
      @locals[:user] = GLogin::Cookie::Closed.new(
        cookies[:glogin],
        settings.config['github']['encryption_secret'],
        context
      ).to_user
    rescue OpenSSL::Cipher::CipherError => _
      cookies.delete(:glogin)
    end
  end
end

get '/github-callback' do
  cookies[:glogin] = GLogin::Cookie::Open.new(
    settings.glogin.user(params[:code]),
    settings.config['github']['encryption_secret'],
    context
  ).to_s
  flash('/', 'You have been logged in')
end

get '/logout' do
  cookies.delete(:glogin)
  flash('/', 'You have been logged out')
end

get '/' do
  flash('/ranked', 'Thanks for logging in') if @locals[:user]
  haml :index, layout: :layout, locals: merged(
    title: '/'
  )
end

get '/ranked' do
  query = params[:q] || ''
  path = (params[:path] || '').split(' ')
  mnemo = params[:mnemo] || '*'
  haml :ranked, layout: :layout, locals: merged(
    title: '/risks',
    path: path,
    mnemo: mnemo,
    query: query,
    ranked: ranked.fetch(query: query, chunks: path, mnemo: mnemo, offset: 0, limit: 10)
  )
end

get '/ranked/delete' do
  path = params[:path]
  ranked.delete(path)
  flash('/ranked', "The item ##{id} deleted")
end

get '/agenda' do
  agenda.refresh
  query = params[:q] || ''
  haml :agenda, layout: :layout, locals: merged(
    title: '/agenda',
    query: query,
    agenda: agenda.fetch(query: query, offset: 0, limit: 10)
  )
end

get '/agenda/done' do
  agenda.done(params[:pid].to_i)
  flash('/agenda', 'Thanks!')
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

get '/causes.json' do
  content_type('application/json')
  JSON.pretty_generate(causes.fetch(query: params[:query] || ''))
end

get '/risks.json' do
  content_type('application/json')
  JSON.pretty_generate(risks.fetch(query: params[:query] || ''))
end

get '/effects.json' do
  content_type('application/json')
  JSON.pretty_generate(effects.fetch(query: params[:query] || ''))
end

get '/plans.json' do
  content_type('application/json')
  JSON.pretty_generate(plans.fetch(query: params[:query] || ''))
end

get '/add' do
  chunks = (params[:path] || '').split(' ')
  vars = { title: '/add' }
  chunks.each do |c|
    i = links.item(c)
    vars[i.mnemo.downcase + '_item'] = i
    vars['probability'] = i.probability if i.respond_to?(:probability)
    vars['impact'] = i.impact if i.respond_to?(:impact)
    vars['schedule'] = i.schedule if i.respond_to?(:schedule)
  end
  haml :add, layout: :layout, locals: merged(vars)
end

post '/do-add' do
  cid = params[:cid].empty? ? causes.add(params[:cause].strip) : params[:cid]
  rid = params[:rid].empty? ? (risks.add(params[:risk].strip) unless params[:risk].empty?) : params[:rid]
  eid = params[:eid].empty? ? (effects.add(params[:effect].strip) unless params[:effect].empty?) : params[:eid]
  pid = params[:pid].empty? ? (plans.add(params[:plan].strip) unless params[:plan].empty?) : params[:pid]
  causes.get(cid).text = params[:cause].strip if params[:cause]
  risks.get(rid).text = params[:risk].strip if params[:risk]
  effects.get(eid).text = params[:effect].strip if params[:effect]
  plans.get(pid).text = params[:plan].strip if params[:plan]
  links.add("C#{cid}", "R#{rid}") if cid && rid
  links.add("R#{rid}", "E#{eid}") if rid && eid
  links.add("C#{eid}", "P#{pid}") if pid && cid && !rid && !eid
  links.add("R#{rid}", "P#{pid}") if pid && rid && !eid
  links.add("E#{eid}", "P#{pid}") if pid && eid
  risks.get(rid).probability = params[:probability].to_i if rid && params[:probability]
  effects.get(eid).impact = params[:impact].to_i if eid && params[:impact]
  plans.get(pid).schedule = params[:schedule].strip if pid && params[:schedule]
  ranked.analyze('C', "C#{cid}")
  ranked.analyze('CR', "C#{cid} R#{rid}") if rid
  ranked.analyze('CRE', "C#{cid} R#{rid} E#{eid}") if rid && eid
  ranked.analyze('CREP', "C#{cid} R#{rid} E#{eid} P#{pid}") if rid && eid && pid
  agenda.analyze(pid) if pid
  flash('/ranked', 'Thanks')
end

get '/js/*.js' do
  file = File.join('js', params[:splat].first) + '.js'
  error(404, "File not found: #{file}") unless File.exist?(file)
  content_type 'application/javascript'
  IO.read(file)
end

get '/robots.txt' do
  content_type 'text/plain'
  "User-agent: *\nDisallow: /"
end

get '/version' do
  content_type 'text/plain'
  Rsk::VERSION
end

not_found do
  status 404
  content_type 'text/html', charset: 'utf-8'
  haml :not_found, layout: :layout, locals: merged(
    title: request.url
  )
end

error do
  status 503
  e = env['sinatra.error']
  if e.is_a?(Rsk::Urror)
    flash('/', e.message, color: 'darkred')
  else
    Raven.capture_exception(e)
    haml(
      :error,
      layout: :layout,
      locals: merged(
        title: 'error',
        error: "#{e.message}\n\t#{e.backtrace.join("\n\t")}"
      )
    )
  end
end

def context
  "#{request.ip} #{request.user_agent} #{Rsk::VERSION} #{Time.now.strftime('%Y/%m')}"
end

def merged(hash)
  out = @locals.merge(hash)
  out[:local_assigns] = out
  if cookies[:flash_msg]
    out[:flash_msg] = cookies[:flash_msg]
    cookies.delete(:flash_msg)
  end
  out[:flash_color] = cookies[:flash_color] || 'darkgreen'
  cookies.delete(:flash_color)
  out
end

def flash(uri, msg, color: 'darkgreen')
  cookies[:flash_msg] = msg
  cookies[:flash_color] = color
  redirect uri
end

def current_user
  redirect '/hello' unless @locals[:user]
  @locals[:user][:login].downcase
end

def current_project
  pid = @cookies['0rsk-project']
  flash('/projects', 'Pick up a project to work with, or create a new one') unless pid
  pid
end

def projects
  require_relative 'objects/projects'
  Rsk::Projects.new(settings.pgsql, current_user)
end

def ranked(project: current_project)
  require_relative 'objects/ranked'
  Rsk::Ranked.new(settings.pgsql, project)
end

def agenda
  require_relative 'objects/agenda'
  Rsk::Agenda.new(settings.pgsql, current_user)
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

def links(project: current_project)
  require_relative 'objects/links'
  Rsk::Links.new(settings.pgsql, project)
end
