# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require 'securerandom'
require_relative '../objects/telechats'

class Rsk::TelechatsTest < TestCase
  def test_checks
    telechats = Rsk::Telechats.new(test_pgsql)
    chat = SecureRandom.random_number(2_000_000_000) + 1
    telechats.add(chat, "judy#{rand(99_999)}")
    msg = 'hey, you!'
    telechats.posted(msg, chat)
    refute(telechats.diff?(msg, chat))
    assert(telechats.diff?('something else', chat))
  end

  def test_adds_and_fetches
    login = "judyAF#{rand(99_999)}"
    telechats = Rsk::Telechats.new(test_pgsql)
    chat = SecureRandom.random_number(2_000_000_000) + 1
    telechats.add(chat, login)
    assert(telechats.exists?(chat))
    assert_equal(login, telechats.login(chat))
    assert_equal(chat, telechats.chat(login))
  end

  def test_wired
    login = "judyW#{rand(99_999)}"
    telechats = Rsk::Telechats.new(test_pgsql)
    refute(telechats.wired?(login))
    telechats.add(SecureRandom.random_number(2_000_000_000) + 1, login)
    assert(telechats.wired?(login))
  end

  def test_double_add
    telechats = Rsk::Telechats.new(test_pgsql)
    chat = SecureRandom.random_number(2_000_000_000) + 1
    telechats.add(chat, "judyDA#{SecureRandom.hex(8)}")
    assert_raises(Rsk::Urror) do
      telechats.add(chat, "other#{SecureRandom.hex(8)}")
    end
  end

  def test_accepts_a_modern_telegram_chat
    login = "judyBI#{SecureRandom.hex(8)}"
    telechats = Rsk::Telechats.new(test_pgsql)
    chat = 5_000_000_000 + SecureRandom.random_number(1_000_000_000)
    telechats.add(chat, login)
    assert_equal(chat, telechats.chat(login))
  end

  def test_accepts_a_supergroup_chat
    login = "judySG#{SecureRandom.hex(8)}"
    telechats = Rsk::Telechats.new(test_pgsql)
    chat = -(1_001_000_000_000 + SecureRandom.random_number(1_000_000_000))
    telechats.add(chat, login)
    assert_equal(chat, telechats.chat(login))
  end

  def test_relinks_from_another_chat
    login = "judyRL#{SecureRandom.hex(8)}"
    telechats = Rsk::Telechats.new(test_pgsql)
    first = SecureRandom.random_number(2_000_000_000) + 1
    second = SecureRandom.random_number(2_000_000_000) + 1
    telechats.add(first, login)
    telechats.add(second, login)
    assert_equal(second, telechats.chat(login))
    refute(telechats.exists?(first))
  end

  def test_adds_the_same_chat_twice
    login = "judyST#{SecureRandom.hex(8)}"
    telechats = Rsk::Telechats.new(test_pgsql)
    chat = SecureRandom.random_number(2_000_000_000) + 1
    telechats.add(chat, login)
    telechats.add(chat, login)
    assert_equal(chat, telechats.chat(login))
  end
end
