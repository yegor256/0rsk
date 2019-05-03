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
  telebot.send_message(
    chat_id: chat,
    parse_mode: 'Markdown',
    disable_web_page_preview: true,
    text: msg,
    reply_markup: reply_markup
  )
end

def reply(msg, login)
  if %r{^/done$}.match?(msg)
    left = tasks(login: login).fetch
    if left.empty?
      ['There are no tasks in your agenda, nothing to complete.']
    else
      Telebot::ReplyKeyboardMarkup.new(
        keyboard: [
          left.map do |t|
            {
              text: "/done #{t[:id]}"
            }
          end
        ],
        one_time_keyboard: true,
        resize_keyboard: true
      )
    end
  elsif %r{^/done [0-9]+$}.match?(msg)
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
        list.map { |t| "\n\n" + task_md(t) }
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
  Rsk::Daemon.new.start do
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
        if response.is_a?(Array)
          telepost(response.flatten.join(' '), chat)
        else
          telepost('Please, go on:', chat, reply_markup: response)
        end
      else
        telepost("[Click here](https://www.0rsk.com/telegram?id=#{chat}) to identify yourself.", chat)
      end
    end
  end
end

if settings.config['telegram']
  Rsk::Daemon.new(10).start do
    users.fetch.each do |login|
      next unless telechats.wired?(login)
      chat = telechats.chat_of(login)
      expired = telepings.expired(login)
      next if expired.empty?
      telepost(
        [
          "Let me remind you that there are #{expired.count} tasks still required to be completed:",
          expired.map { |t| task_md(tasks(login: login).fetch(query: t)[0]) },
          'When done with a task, say /done and I will remove it from the agenda.'
        ].flatten.join("\n\n"),
        chat
      )
      expired.each { |t| telepings.add(t, chat) }
    end
  end
end

def task_md(task)
  [
    "[T#{task[:id]}](https://www.0rsk.com/responses?id=#{task[:triple]})",
    "\"#{task[:text]}\"",
    "in [#{task[:title]}](https://www.0rsk.com/projects/#{task[:pid]}):",
    "#{task[:ctext]}; #{task[:rtext]}; #{task[:etext]}",
    "(#{task[:schedule]})"
  ].join(' ')
end