# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'yaml'
require_relative '../objects/causes'
require_relative '../objects/rsk'
require_relative 'test__helper'

class Rsk::ProjectsTest < TestCase
  def test_adds_and_fetches
    projects = Rsk::Projects.new(test_pgsql, 'jeff11')
    pid = projects.add('test')
    assert_predicate(pid, :positive?)
    assert(projects.exists?(pid))
    projects.delete(pid)
    refute(projects.exists?(pid))
  end

  def test_deletes_with_triple
    projects = Rsk::Projects.new(test_pgsql, 'jeff094')
    project_id = projects.add("testfs#{rand(99_999)}")
    Rsk::Triples.new(test_pgsql, project_id).add(
      Rsk::Causes.new(test_pgsql, project_id).add('we have data'),
      Rsk::Risks.new(test_pgsql, project_id).add('we may lose it'),
      Rsk::Effects.new(test_pgsql, project_id).add('business will stop NOW')
    )
    projects.delete(project_id)
    assert_empty(test_pgsql.exec('SELECT id FROM project WHERE id = $1', [project_id]).to_a)
  end
end
