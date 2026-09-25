# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../objects/role'
require_relative 'test__helper'

class Rsk::RoleTest < Minitest::Test
  def test_web_dyno_runs_no_daemons
    refute_predicate(Rsk::Role.new('web'), :daemons?)
  end

  def test_daemons_dyno_runs_them
    assert_predicate(Rsk::Role.new('daemons'), :daemons?)
  end

  def test_runs_them_when_the_role_is_not_set
    assert_predicate(Rsk::Role.new(nil), :daemons?)
  end
end
