# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../0rsk'

class Rsk::TelegramIncomingTest < TestCase
  def test_skips_an_update_that_carries_no_message
    assert_nil(Object.new.extend(Rsk::Telegram).incoming(nil))
  end
end
