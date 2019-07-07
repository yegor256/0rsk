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

require 'telebot'
require_relative '../objects/urror'
require_relative '../objects/telechats'
require_relative '../objects/telepings'
require_relative '../objects/daemon'

get '/telegram' do
  id = params[:id].to_i
  telechats.add(id, current_user)
  telepost("We identified you as [@#{current_user}](https://github.com/#{current_user}), thanks!")
  flash('/', "Your account linked with Telegram chat ##{id}, thanks!")
end

def telechats
  @telechats ||= Rsk::Telechats.new(settings.pgsql)
end

def telebot
  return nil unless settings.config['telegram']
  @telebot ||= Telebot::Client.new(settings.config['telegram']['token'])
end

def telepings
  @telepings ||= Rsk::Telepings.new(settings.pgsql)
end

def telepost(msg, chat = telechats.chat_of(current_user), reply_markup: nil)
  return unless settings.config['telegram']
  telechats.posted(msg, chat)
  telebot.send_message(
    chat_id: chat,
    parse_mode: 'Markdown',
    disable_web_page_preview: true,
    text: msg.length > 4000 ? msg[0..4000] + '...' : msg,
    reply_markup: reply_markup
  )
end

def reply(msg, login)
  if %r{^/done$}.match?(msg)
    left = tasks(login: login).fetch(limit: 100)
    if left.empty?
      ['There are no tasks in your agenda, nothing to complete.']
    elsif left.count > 16
      [
        "There are #{left.count} tasks in your agenda.",
        'Just pick one and say `/done <id>` and I will understand you.',
        "I can't show you a menu, because you've got so many tasks (#{left.count}),",
        'which is an obvious sign of your management problems :('
      ]
    else
      {
        keyboard: left.sort_by { |t| t[:id] }.map.with_index do |t, i|
          {
            index: i,
            text: "/done #{t[:id]}"
          }
        end.group_by { |x| (x[:index] / 4).round }.values,
        one_time_keyboard: true,
        resize_keyboard: true
      }
    end
  elsif %r{^/done [0-9]+$}.match?(msg)
    id = msg.split(' ')[1].to_i
    tasks(login: login).done(id)
    left = tasks(login: login).fetch
    [
      "Task `T#{id}` was marked as completed, thanks!",
      left.empty? ?
        'Your agenda is empty, good job!' :
        "There are still #{left.count} tasks in your agenda. Say /tasks to see them all."
    ]
  elsif %r{^/tasks$}.match?(msg)
    list = tasks(login: login).fetch(limit: 100)
    if list.empty?
      ['There are no tasks in your agenda, good job!']
    else
      task_list(list)
    end
  else
    [
      "I didn't understand you, but I'm still with you, [#{login}](https://github.com/#{login})!",
      'In this chat I inform you about the most important tasks you have in your agenda',
      'in [0rsk.com](https://www.0rsk.com).'
    ]
  end
end

def process_request(chat, message)
  login = telechats.login_of(chat)
  response = begin
    reply(message.text, login)
  rescue StandardError => e
    Raven.capture_exception(e) unless e.is_a?(Rsk::Urror)
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
  if response.is_a?(Array)
    telepost(response.flatten.join(' '), chat)
  else
    telepost('Please, go on:', chat, reply_markup: response)
  end
end

if settings.config['telegram']
  Rsk::Daemon.new.start do
    Telebot::Bot.new(settings.config['telegram']['token']).run do |_, message|
      chat = message.chat.id
      if telechats.exists?(chat)
        process_request(chat, message)
      else
        telepost("[Click here](https://www.0rsk.com/telegram?id=#{chat}) to identify yourself.", chat)
      end
    end
  end
end

def notify_all
  users.fetch.each do |login|
    next unless telechats.wired?(login)
    chat = telechats.chat_of(login)
    fresh = telepings.fresh(login)
      .map { |tid| tasks(login: login).fetch(query: tid)[0] }
      .sort_by { |t| t[:rank] }
      .reverse
    if fresh.empty?
      list = tasks(login: login).fetch(limit: 100)
      next unless telepings.required(login)
      next if list.empty?
      msg = [
        'Let me remind you that there are some tasks still required to be completed.',
        task_list(list),
        "\n\nWhen done with a task, say /done and I will remove it from the agenda."
      ].flatten.join(' ')
      telepost(msg, chat) if telechats.diff?(msg, chat)
      list.each { |t| telepings.add(t[:id], chat) }
    else
      telepost(
        [
          fresh.count > 1 ? 'There are some new tasks for you.' : 'There is a new task for you.',
          task_list(fresh)
        ].flatten.join(' '),
        chat
      )
      fresh.each { |t| telepings.add(t[:id], chat) }
    end
  end
end

if settings.config['telegram']
  Rsk::Daemon.new(10).start do
    notify_all
  end
end

def task_list(list)
  if list.count < 8
    [
      'Here is a full list of them:',
      list.map do |t|
        [
          "\n\n[T#{t[:id]}](https://www.0rsk.com/responses?id=#{t[:triple]})",
          "(#{t[:positive] ? '+' : '-'}#{t[:rank]})",
          t[:text].inspect,
          "in [#{t[:title]}](https://www.0rsk.com/projects/#{t[:pid]}):",
          "#{t[:ctext]}; #{t[:rtext]}; #{t[:etext]}",
          "(#{t[:schedule]})"
        ].join(' ')
      end
    ]
  elsif list.count < 16
    [
      "There are #{list.count} tasks in the list:\n",
      list.map do |t|
        [
          "\n  `T#{t[:id]}` (#{t[:positive] ? '+' : '-'}#{t[:rank]})",
          t[:text].inspect,
          "#{t[:ctext]}; #{t[:rtext]}; #{t[:etext]}"
        ].join(' ')
      end
    ]
  else
    [
      "There are too many tasks in the list (#{list.count}), here is the top of it:\n",
      list.take(16).map { |t| "\n`T#{t[:id]}` (#{t[:positive] ? '+' : '-'}#{t[:rank]}) #{t[:text].inspect}" }
    ]
  end
end
