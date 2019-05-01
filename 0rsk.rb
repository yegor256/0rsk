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
    password: cfg['pgsql']['password'],
    log: nil
  ).start(4)
end

before '/*' do
  @locals = {
    ver: Rsk::VERSION,
    login_link: settings.glogin.login_uri,
    request_ip: request.ip,
    iri: Iri.new(request.url)
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
  code = params[:code]
  error(400) if code.nil?
  cookies[:glogin] = GLogin::Cookie::Open.new(
    settings.glogin.user(code),
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
    triples: triples.fetch(query: query, offset: offset, limit: limit)
  )
end

get '/ranked/delete' do
  id = params[:id]
  triples.delete(id)
  flash('/ranked', "The ranked triple ##{id} deleted")
end

get '/tasks' do
  offset = [(params[:offset] || '0').to_i, 0].max
  limit = (params[:limit] || '25').to_i
  query = params[:q] || ''
  haml :tasks, layout: :layout, locals: merged(
    title: '/tasks',
    offset: offset,
    limit: limit,
    query: query,
    tasks: tasks.fetch(query: query, offset: offset, limit: limit),
    wired: telechats.wired?(current_user)
  )
end

get '/tasks/done' do
  id = params[:id].to_i
  tasks.done(id)
  flash('/tasks', "Thanks, task ##{id} was completed!")
end

get '/tasks/create' do
  tasks.create
  flash('/tasks', 'All necessary tasks were created, thanks!')
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
  JSON.pretty_generate(
    causes.fetch(query: params[:query] || '').map do |r|
      {
        label: "C#{r[:id]}: #{r[:text]}",
        value: r[:text],
        fields: {
          cid: r[:id]
        }
      }
    end
  )
end

get '/risks.json' do
  content_type('application/json')
  JSON.pretty_generate(
    risks.fetch(query: params[:query] || '').map do |r|
      {
        label: "R#{r[:id]}: #{r[:text]}",
        value: r[:text],
        fields: {
          rid: r[:id],
          probability: r[:probability]
        }
      }
    end
  )
end

get '/effects.json' do
  content_type('application/json')
  JSON.pretty_generate(
    effects.fetch(query: params[:query] || '').map do |r|
      {
        label: "E#{r[:id]}: #{r[:text]}",
        value: r[:text],
        fields: {
          eid: r[:id],
          impact: r[:impact]
        }
      }
    end
  )
end

get '/plans.json' do
  content_type('application/json')
  JSON.pretty_generate(
    plans.fetch(query: params[:query] || '').map do |r|
      {
        label: "P#{r[:id]}: #{r[:text]}",
        value: r[:text],
        fields: {
          pid: r[:id],
          schedule: r[:schedule]
        }
      }
    end
  )
end

get '/triple' do
  vars = { title: '/triple', project: current_project }
  id = params[:id].to_i
  if id.positive?
    triple = triples.fetch(query: id, limit: 1)[0]
    raise Rsk::Urror, "Triple ##{id} not found" if triple.nil?
    vars[:triple] = triple
  end
  haml :triple, layout: :layout, locals: merged(vars)
end

post '/triple/save' do
  ctext = params[:ctext].strip
  rtext = params[:rtext].strip
  etext = params[:etext].strip
  cid = params[:cid].empty? ? causes.add(ctext) : params[:cid]
  rid = params[:rid].empty? ? risks.add(rtext) : params[:rid]
  eid = params[:eid].empty? ? effects.add(etext) : params[:eid]
  causes.get(cid).text = ctext
  risks.get(rid).text = rtext
  effects.get(eid).text = etext
  risks.get(rid).probability = params[:probability].to_i
  effects.get(eid).impact = params[:impact].to_i
  effects.get(eid).positive = !params[:positive].nil?
  tid = triples.add(cid, rid, eid)
  flash("/responses?id=#{tid}", "Thanks, the triple ##{tid} successfully saved!")
end

get '/responses' do
  id = params[:id].to_i
  triple = triples.fetch(query: id, limit: 1)[0]
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
  plans.get(pid).schedule = params[:schedule].strip
  flash("/responses?id=#{id}", "Thanks, plan ##{pid} added to the triple ##{id}")
end

get '/responses/detach' do
  tid = params[:tid].to_i
  id = params[:id].to_i
  part = params[:part].to_i
  plans.detach(id, part)
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
    plans: plans.fetch(query: query, offset: offset, limit: limit)
  )
end

get '/telegram' do
  id = params[:id].to_i
  telechats.add(id, current_user)
  telepost("We identified you as [@#{current_user}](https://github.com/#{current_user}), thanks!")
  flash('/', "Your account linked with Telegram chat ##{id}, thanks!")
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
    flash(@locals[:user] ? '/ranked' : '/', e.message, color: 'darkred')
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

def flash(uri, msg = '', color: 'darkgreen')
  cookies[:flash_msg] = msg
  cookies[:flash_color] = color
  redirect(uri)
end

def current_user
  redirect '/' unless @locals[:user]
  @locals[:user][:login].downcase
end

def current_project
  pid = @cookies['0rsk-project']
  flash('/projects', 'Pick up a project to work with, or create a new one') unless pid
  unless projects.exists?(pid)
    @cookies.delete('0rsk-project')
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

def tasks(login: current_user)
  require_relative 'objects/tasks'
  Rsk::Tasks.new(settings.pgsql, login)
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

def telechats
  require_relative 'objects/telechats'
  @telechats ||= Rsk::Telechats.new(settings.pgsql)
end

def telebot
  return nil unless settings.config['telegram']
  @telebot ||= Telebot::Client.new(settings.config['telegram']['token'])
end

def telepings
  require_relative 'objects/telepings'
  @telepings ||= Rsk::Telepings.new(settings.pgsql)
end

def telepost(msg, chat = telechats.chat_of(current_user))
  return unless settings.config['telegram']
  telebot.send_message(
    chat_id: chat,
    parse_mode: 'Markdown',
    disable_web_page_preview: true,
    text: msg
  )
end

def reply(msg, login)
  if %r{^/done [0-9]+$}.match?(msg)
    id = msg.split(' ')[1].to_i
    tasks(login: login).done(id)
    left = tasks(login: login).fetch
    [
      "Task `T#{id}` was marked as completed, thanks!",
      left.empty? ? 'Your agenda is empty, good job!' : "There are still #{left.count} tasks in your agenda."
    ]
  elsif %r{^/tasks$}.match?(msg)
    list = tasks(login: login).fetch
    if list.empty?
      ['There are no tasks in your agenda, good job!']
    else
      [
        'Here is a full list of tasks that belong to you:',
        list.map do |t|
          "\n\n" + [
            "[T#{t[:id]}](https://www.0rsk.com/responses?id=#{t[:triple]}):",
            "\"#{t[:text]}\" in [#{t[:title]}](https://www.0rsk.com/projects/#{t[:pid]})",
            "\n#{t[:ctext]}; #{t[:rtext]}; #{t[:etext]}"
          ].join(' ')
        end
      ]
    end
  else
    [
      "I didn't understand you, but I'm still with you, [#{login}](https://github.com/#{login})!",
      'In this chat I inform you about the most important tasks you have in your agenda',
      'in [0rsk.com](https://www.0rsk.com).'
    ]
  end
end

if settings.config['telegram']
  Thread.start do
    Telebot::Bot.new(settings.config['telegram']['token']).run do |_, message|
      chat = message.chat.id
      if telechats.exists?(chat)
        login = telechats.login_of(chat)
        response = begin
          reply(message.text, login)
        rescue StandardError => e
          [
            "Oops, there was a problem with your request, [#{login}](https://github.com/#{login}):\n\n",
            "```\n#{e.message}\n```\n\nMost probably",
            'you did something wrong, but this could also be a defect on the server.',
            'If you think it\'s our bug, please, report it to us via a GitHub issue,',
            '[here](https://github.com/yegor256/0rsk/issues).',
            'We will take care of it as soon as we can.',
            'Thanks, we appreciate your help and your patience!'
          ]
        end
        telepost(response.flatten.join(' '), chat)
      else
        telepost("[Click here](https://www.0rsk.com/telegram?id=#{chat}) to identify yourself.", chat)
      end
    end
  end
end

if settings.config['telegram']
  Thread.start do
    sleep(10 * 60)
    users.fetch.each do |login|
      next unless telechats.wired?(login)
      chat = telechats.chat_of(login)
      expired = telepings.expired(login)
      next if expired.empty?
      telepost(
        [
          "There are #{expired.count} tasks still required to be completed:",
          expired.map do |t|
            task = tasks(login: login).fetch(query: t)[0]
            [
              "`T#{task[:id]}` \"#{task[:text]}\"",
              "in [#{task[:title]}](https://www.0rsk.com/projects/#{task[:pid]}):",
              "#{task[:ctext]}; #{task[:rtext]}; #{task[:etext]}."
            ].join(' ')
          end
        ].flatten.join("\n\n"),
        chat
      )
      expired.each { |t| telepings.add(t, chat) }
    end
  end
end

Thread.start do
  sleep(10 * 60)
  users.fetch.each do |login|
    tasks(login: login).create
  end
end
