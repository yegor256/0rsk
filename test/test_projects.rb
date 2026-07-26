# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'yaml'
require_relative '../objects/causes'
require_relative '../objects/rsk'
require_relative 'test__helper'

class Rsk::ProjectsTest < TestCase
  def test_adds_and_fetches
    projects = Rsk::Projects.new(fake_pgsql, 'jeff11')
    pid = projects.add('test')
    assert_predicate(pid, :positive?)
    assert(projects.exists?(pid))
    projects.delete(pid)
    refute(projects.exists?(pid))
  end

  def test_deletes_with_triple
    projects = Rsk::Projects.new(fake_pgsql, 'jeff094')
    project = projects.add("testfs#{rand(99_999)}")
    Rsk::Triples.new(fake_pgsql, project).add(
      Rsk::Causes.new(fake_pgsql, project).add('we have data'),
      Rsk::Risks.new(fake_pgsql, project).add('we may lose it'),
      Rsk::Effects.new(fake_pgsql, project).add('business will stop NOW')
    )
    projects.delete(project)
  end
end
