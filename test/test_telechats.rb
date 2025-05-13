# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../objects/telechats'

# Test of Telechats.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::TelechatsTest < Minitest::Test
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
end
