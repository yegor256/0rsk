# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

ENV['RACK_ENV'] = 'test'

require 'simplecov'
require 'simplecov-cobertura'
unless SimpleCov.running || ENV['PICKS']
  SimpleCov.command_name('test')
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
    [
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::CoberturaFormatter
    ]
  )
  SimpleCov.minimum_coverage 30
  SimpleCov.minimum_coverage_by_file 10
  SimpleCov.start do
    add_filter 'test/'
    add_filter 'vendor/'
    add_filter 'target/'
    track_files 'front/**.rb'
    track_files 'objects/**.rb'
    track_files '0rsk.rb'
  end
end

require 'minitest/autorun'
require 'minitest/manual_plugins'
require 'minitest/reporters'
Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]
Minitest.load :minitest_reporter

require 'loog'
require 'pgtk/pool'
require 'yaml'
require 'securerandom'

require_relative '../objects/rsk'
require_relative '../objects/causes'
require_relative '../objects/risks'
require_relative '../objects/effects'
require_relative '../objects/projects'
require_relative '../objects/triples'
require_relative '../objects/plans'
require_relative '../objects/tasks'
require_relative '../objects/pipeline'
require_relative '../objects/users'
require_relative '../objects/trackers'

class Minitest::Test
  def test_pgsql
    # rubocop:disable Style/ClassVars
    @@test_pgsql ||= Pgtk::Pool.new(
      Pgtk::Wire::Yaml.new(File.join(__dir__, '../target/pgsql-config.yml')),
      log: Loog::NULL
    ).start
    # rubocop:enable Style/ClassVars
  end

  def make_project(pgsql, name: 'test')
    login = "#{name}#{SecureRandom.hex(6)}"
    pid = Rsk::Projects.new(pgsql, login).add("p#{SecureRandom.hex(6)}")
    [login, pid]
  end

  def make_cause(pgsql, project, text: 'we have data')
    Rsk::Causes.new(pgsql, project).add(text)
  end

  def make_risk(pgsql, project, text: 'we may lose it')
    Rsk::Risks.new(pgsql, project).add(text)
  end

  def make_effect(pgsql, project, text: 'business will stop')
    Rsk::Effects.new(pgsql, project).add(text)
  end

  def make_triple(pgsql, project, cause: 'we have data', risk: 'we may lose it', effect: 'business will stop')
    cid = make_cause(pgsql, project, text: cause)
    rid = make_risk(pgsql, project, text: risk)
    eid = make_effect(pgsql, project, text: effect)
    tid = Rsk::Triples.new(pgsql, project).add(cid, rid, eid)
    { cause: cid, risk: rid, effect: eid, triple: tid }
  end

  def make_plan(pgsql, project, part, text: 'solve it!')
    plans = Rsk::Plans.new(pgsql, project)
    pid = plans.add(part, text)
    plans.get(pid, part).schedule = (Time.now - (5 * 24 * 60 * 60)).strftime('%d-%m-%Y')
    pid
  end

  def make_task(pgsql)
    login, pid = make_project(pgsql)
    t = make_triple(pgsql, pid)
    plan_id = make_plan(pgsql, pid, t[:effect])
    tasks = Rsk::Tasks.new(pgsql, login)
    tasks.create
    { login: login, project: pid, **t, plan: plan_id, task: tasks.fetch[0] }
  end
end
