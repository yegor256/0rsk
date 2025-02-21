# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'rack/test'
require 'yaml'
require_relative 'test__helper'
require_relative '../objects/rsk'
require_relative '../objects/causes'

# Test of Projects.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::ProjectsTest < Minitest::Test
  def test_adds_and_fetches
    projects = Rsk::Projects.new(test_pgsql, 'jeff11')
    pid = projects.add('test')
    assert(pid.positive?)
    assert(projects.exists?(pid))
    projects.delete(pid)
    assert(!projects.exists?(pid))
  end

  def test_deletes_with_triple
    projects = Rsk::Projects.new(test_pgsql, 'jeff094')
    project = projects.add("testfs#{rand(99_999)}")
    cid = Rsk::Causes.new(test_pgsql, project).add('we have data')
    rid = Rsk::Risks.new(test_pgsql, project).add('we may lose it')
    eid = Rsk::Effects.new(test_pgsql, project).add('business will stop NOW')
    triples = Rsk::Triples.new(test_pgsql, project)
    triples.add(cid, rid, eid)
    projects.delete(project)
  end
end
