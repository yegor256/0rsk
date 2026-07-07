# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../objects/projects'
require_relative '../objects/rsk'
require_relative '../objects/users'

class Rsk::UsersTest < TestCase
  def test_adds_and_fetches
    login = "bobbydick#{rand(99_999)}"
    projects = Rsk::Projects.new(fake_pgsql, login)
    projects.add("test-i#{rand(99_999)}")
    projects.add("test-b#{rand(99_999)}")
    users = Rsk::Users.new(fake_pgsql)
    assert_equal(users.fetch.count, users.fetch.uniq.count)
    assert_includes(users.fetch, login)
  end
end
