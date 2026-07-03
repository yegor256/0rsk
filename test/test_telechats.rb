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
    telechats.add(chat, "judyDA#{rand(99_999)}")
    assert_raises(PG::UniqueViolation) do
      telechats.add(chat, 'other')
    end
  end
end
