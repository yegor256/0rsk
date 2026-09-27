# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../0rsk'

class Rsk::TelegramReplyTest < TestCase
  def test_answers_a_command_that_carries_a_bot_name
    assert_includes(said('/tasks@zerorsk_bot'), 'agenda', 'a command in a group must be understood')
  end

  def test_refuses_a_command_buried_in_a_message
    assert_includes(said("please\n/done 7"), "didn't understand", 'only the whole message is a command')
  end

  private

  def said(msg)
    empty = Object.new
    empty.define_singleton_method(:fetch) { |**| [] }
    bot = Object.new.extend(Rsk::Telegram)
    bot.define_singleton_method(:tasks) { |**| empty }
    bot.reply(msg, 'jeff').flatten.join(' ')
  end
end
