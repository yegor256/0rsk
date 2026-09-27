# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'securerandom'
require_relative 'test__helper'

require_relative '../objects/projects'

class Rsk::ProjectsTitleTest < TestCase
  def test_refuses_an_empty_title
    projects = Rsk::Projects.new(test_pgsql, "u#{SecureRandom.hex(8)}")
    ['', '   ', nil].each do |bad|
      assert_raises(Rsk::Urror, "title #{bad.inspect} must be refused") { projects.add(bad) }
    end
  end

  def test_refuses_a_title_longer_than_the_column
    projects = Rsk::Projects.new(test_pgsql, "u#{SecureRandom.hex(8)}")
    assert_raises(Rsk::Urror) { projects.add('t' * 200) }
  end

  def test_trims_the_title
    projects = Rsk::Projects.new(test_pgsql, "u#{SecureRandom.hex(8)}")
    title = "p#{SecureRandom.hex(8)}"
    projects.add("  #{title}  ")
    assert_equal(title, projects.fetch[0][:title])
  end
end
