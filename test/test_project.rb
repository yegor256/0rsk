# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

require_relative '../objects/project'
require_relative '../objects/projects'
require_relative '../objects/rsk'

class Rsk::ProjectTest < TestCase
  def test_fetches_login
    login = "plin#{SecureRandom.hex(8)}"
    assert_equal(
      login,
      Rsk::Project.new(
        test_pgsql,
        Rsk::Projects.new(test_pgsql, login).add("t#{SecureRandom.hex(8)}")
      ).login
    )
  end
end
