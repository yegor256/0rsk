# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

class Rsk::UsersTest < Minitest::Test
  def test_adds_and_fetches
    login, _pid = make_project(test_pgsql)
    make_project(test_pgsql)
    users = Rsk::Users.new(test_pgsql)
    assert_equal(users.fetch.count, users.fetch.uniq.count)
    assert_includes(users.fetch, login)
  end
end
