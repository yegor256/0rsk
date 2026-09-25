# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../objects/projects'
require_relative '../objects/rsk'
require_relative '../objects/trackers'
require_relative 'test__helper'

class Rsk::ProjectsDeleteTrackerTest < TestCase
  def test_deletes_project_that_has_tracker
    projects = Rsk::Projects.new(test_pgsql, "u#{SecureRandom.hex(8)}")
    pid = projects.add("t#{SecureRandom.hex(8)}")
    Rsk::Trackers.new(test_pgsql, pid).add("yegor256/#{SecureRandom.hex(8)}", SecureRandom.hex(8))
    projects.delete(pid)
    assert_empty(test_pgsql.exec('SELECT id FROM project WHERE id = $1', [pid]).to_a)
  end
end
