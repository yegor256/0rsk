# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'rack/test'
require_relative 'test__helper'
require_relative '../objects/rsk'
require_relative '../objects/projects'
require_relative '../objects/users'

# Test of Users.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::UsersTest < Minitest::Test
  def test_adds_and_fetches
    login = "bobbydick#{rand(99_999)}"
    projects = Rsk::Projects.new(test_pgsql, login)
    projects.add("test-i#{rand(99_999)}")
    projects.add("test-b#{rand(99_999)}")
    users = Rsk::Users.new(test_pgsql)
    assert_equal(users.fetch.count, users.fetch.uniq.count)
    assert_includes(users.fetch, login)
  end
end
