# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../objects/rsk'
require_relative '../objects/projects'
require_relative '../objects/project'

class Rsk::ProjectTest < Minitest::Test
  def test_fetches_login
    login = "plin#{rand(99_999)}"
    pid = Rsk::Projects.new(test_pgsql, login).add("t#{rand(99_999)}")
    assert_equal(login, Rsk::Project.new(test_pgsql, pid).login)
  end
end
