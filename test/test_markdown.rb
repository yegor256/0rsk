# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../objects/markdown'
require_relative '../objects/trimmed'

class Rsk::MarkdownTest < TestCase
  def test_escapes_the_entities
    assert_equal('review \\[pending\\] docs', Rsk::Markdown.new('review [pending] docs').to_s)
    assert_equal('budget\\_2026\\_q1', Rsk::Markdown.new('budget_2026_q1').to_s)
    assert_equal('a\\*b\\`c', Rsk::Markdown.new('a*b`c').to_s)
    assert_equal('\\\\', Rsk::Markdown.new('\\').to_s)
  end

  def test_leaves_plain_text_alone
    assert_equal('we make backups', Rsk::Markdown.new('we make backups').to_s)
  end

  def test_keeps_a_short_text
    assert_equal("a\nb", Rsk::Trimmed.new("a\nb", 100).to_s)
  end

  def test_cuts_on_a_line_boundary
    assert_equal("one\ntwo...", Rsk::Trimmed.new("one\ntwo\nthree and more", 12).to_s)
  end

  def test_cuts_a_single_line
    assert_equal('ab...', Rsk::Trimmed.new('abcdefghij', 5).to_s)
  end

  def test_escape_boundary
    value = Rsk::Trimmed.new('aaaaaa\\_tail', 10).to_s
    refute(value.end_with?('\\'))
    assert_operator(value.length, :<=, 10)
  end

  def test_does_not_leave_an_open_markdown_link
    value = Rsk::Trimmed.new('xxxx [link](https://example.com)', 20).to_s
    assert_equal(value.count('['), value.count(']'))
    assert_equal(value.count('('), value.count(')'))
    assert_operator(value.length, :<=, 20)
  end
end
