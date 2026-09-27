# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../0rsk'

class Rsk::TelepostTest < TestCase
  def test_forgets_a_message_that_never_went_out
    seen = []
    chats = Object.new
    chats.define_singleton_method(:posted) { |msg, _chat| seen << msg }
    bot = Object.new.extend(Rsk::Telegram)
    bot.define_singleton_method(:telechats) { chats }
    bot.define_singleton_method(:settings) do
      Object.new.tap { |s| s.define_singleton_method(:config) { { 'telegram' => { 'token' => 'x' } } } }
    end
    bot.define_singleton_method(:telebot) do
      Object.new.tap do |t|
        t.define_singleton_method(:send_message) { |**| raise(RuntimeError, 'Telegram is down') }
      end
    end
    assert_raises(RuntimeError) { bot.telepost('hello', 1) }
    assert_empty(seen, 'a message that failed to go out must not be remembered')
  end
end
