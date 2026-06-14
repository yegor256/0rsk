# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

class Rsk::ProjectsTest < Minitest::Test
  def test_adds_and_fetches
    login, pid = make_project(test_pgsql)
    projects = Rsk::Projects.new(test_pgsql, login)
    assert(projects.fetch.any? { |p| p[:id] == pid })
    assert(projects.exists?(pid))
  end

  def test_deletes_with_triple
    login, pid = make_project(test_pgsql)
    make_triple(test_pgsql, pid)
    Rsk::Projects.new(test_pgsql, login).delete(pid)
    projects = Rsk::Projects.new(test_pgsql, login)
    refute(projects.exists?(pid))
  end
end
