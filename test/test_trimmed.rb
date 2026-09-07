# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../objects/trimmed'

class Rsk::TrimmedTest < TestCase
  def test_keeps_a_short_text_as_it_is
    assert_equal('hello', Rsk::Trimmed.new('hello', 4000).to_s)
  end

  def test_cuts_at_the_last_line_break
    assert_equal("a\nb...", Rsk::Trimmed.new("a\nb\ncdefgh", 6).to_s)
  end

  def test_counts_an_emoji_the_way_telegram_counts_it
    text = '🔥' * 4480
    trimmed = Rsk::Trimmed.new(text, 4000).to_s
    assert_operator(units(trimmed), :<=, 4096, "#{units(trimmed)} units is over the API limit")
  end

  private

  def units(text)
    text.each_char.sum { |c| c.ord > 0xFFFF ? 2 : 1 }
  end
end
