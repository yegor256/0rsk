# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../objects/telechats'

class Rsk::TelechatsTest < Minitest::Test
  def test_checks
    telechats = Rsk::Telechats.new(test_pgsql)
    chat = rand(99_999)
    telechats.add(chat, "judy#{rand(99_999)}")
    msg = 'hey, you!'
    telechats.posted(msg, chat)
    refute(telechats.diff?(msg, chat))
    assert(telechats.diff?('something else', chat))
  end
end
