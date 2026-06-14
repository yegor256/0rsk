# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../objects/telechats'
require_relative '../objects/urror'

# Test of Telechats.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2026 Yegor Bugayenko
# License:: MIT
class Rsk::TelechatsTest < Minitest::Test
  def test_fails_cleanly_when_chat_login_is_absent
    assert_raises(Rsk::Urror) do
      Rsk::Telechats.new(FakeTelechatsPgsql.new).login_of(rand(99_999))
    end
  end

  def test_fails_cleanly_when_chat_id_is_absent
    assert_raises(Rsk::Urror) do
      Rsk::Telechats.new(FakeTelechatsPgsql.new).chat_of("judy#{rand(99_999)}")
    end
  end

  def test_fails_cleanly_when_recent_message_is_absent
    assert_raises(Rsk::Urror) do
      Rsk::Telechats.new(FakeTelechatsPgsql.new).diff?('hello', rand(99_999))
    end
  end

  def test_checks
    login = "judy#{rand(99_999)}"
    telechats = Rsk::Telechats.new(test_pgsql)
    chat = rand(99_999)
    telechats.add(chat, login)
    msg = 'hey, you!'
    telechats.posted(msg, chat)
    refute(telechats.diff?(msg, chat))
    assert(telechats.diff?('something else', chat))
  end

  # Fake PostgreSQL handle that simulates a SELECT returning no rows.
  class FakeTelechatsPgsql
    def exec(_query, _params)
      []
    end
  end
end
