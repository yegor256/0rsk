# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'rake'
require_relative 'test__helper'

class Rsk::SeedDummyTest < TestCase
  def test_seeds_plans_of_every_project
    test_pgsql.exec("DELETE FROM project WHERE login LIKE 'demo\\_%'")
    load(File.join(__dir__, '../Rakefile'))
    capture_io { Rake::Task[:seed_dummy].execute }
    assert_equal(
      6,
      Integer(
        test_pgsql.exec(
          [
            'SELECT COUNT(*) FROM plan',
            'JOIN part ON part.id = plan.id',
            'JOIN project ON project.id = part.project',
            "WHERE project.login LIKE 'demo\\_%'"
          ]
        )[0]['count'], 10
      )
    )
  end
end
