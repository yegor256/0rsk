# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../0rsk'

class Rsk::CsvCellTest < TestCase
  def test_quotes_a_formula_whatever_it_starts_with
    ['=1+1', '@SUM(1)', "\t=cmd|'/c calc'!A1", "\r=1+1", ' -1+1'].each do |bad|
      assert(Object.new.extend(Rsk::App).cell(bad).start_with?("'"), "#{bad.inspect} must be quoted")
    end
  end

  def test_leaves_an_ordinary_text_alone
    ['hello', '3 apples', 'a=b'].each do |good|
      assert_equal(good, Object.new.extend(Rsk::App).cell(good))
    end
  end
end
