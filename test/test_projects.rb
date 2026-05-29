# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'yaml'
require_relative 'test__helper'
require_relative '../objects/rsk'
require_relative '../objects/causes'
require_relative '../objects/effects'
require_relative '../objects/projects'
require_relative '../objects/risks'
require_relative '../objects/triples'

# Test of Projects.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2026 Yegor Bugayenko
# License:: MIT
class Rsk::ProjectsTest < Minitest::Test
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
    pid = projects.add("testfs#{rand(99_999)}")
    cid = Rsk::Causes.new(test_pgsql, pid).add('we have data')
    rid = Rsk::Risks.new(test_pgsql, pid).add('we may lose it')
    eid = Rsk::Effects.new(test_pgsql, pid).add('business will stop NOW')
    tid = Rsk::Triples.new(test_pgsql, pid).add(cid, rid, eid)
    projects.delete(pid)
    assert_empty(test_pgsql.exec('SELECT * FROM triple WHERE id = $1', [tid]))
  end
end
