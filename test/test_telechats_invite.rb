# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'securerandom'
require_relative 'test__helper'

require_relative '../objects/telechats'

class Rsk::TelechatsInviteTest < TestCase
  def test_refuses_a_token_that_is_too_old
    chats = Rsk::Telechats.new(test_pgsql)
    token = chats.invite(rand(1_000_000_000))
    test_pgsql.exec(
      "UPDATE teleinvite SET created = NOW() - INTERVAL '#{Rsk::Telechats::HOURS + 1} hours' WHERE token = $1",
      [token]
    )
    assert_nil(chats.invited(token), 'a stale token names no chat')
    assert_raises(Rsk::Urror) { chats.accept(token, "u#{SecureRandom.hex(8)}") }
  end

  def test_names_the_chat_a_fresh_token_belongs_to
    chats = Rsk::Telechats.new(test_pgsql)
    chat = rand(1_000_000_000)
    assert_equal(chat, chats.invited(chats.invite(chat)))
  end
end
