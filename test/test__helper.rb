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
  SimpleCov.minimum_coverage(30)
  SimpleCov.minimum_coverage_by_file(10)
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
Minitest::Reporters.use!([Minitest::Reporters::SpecReporter.new])
Minitest.load(:minitest_reporter)

require 'loog'
require 'pgtk/pool'
require 'securerandom'
require 'yaml'
require_relative '../objects/causes'
require_relative '../objects/effects'
require_relative '../objects/plans'
require_relative '../objects/projects'
require_relative '../objects/risks'
require_relative '../objects/triples'

class TestCase < Minitest::Test
  def test_pgsql
    @@mtx ||= Mutex.new
    @@mtx.synchronize do
      @@test_pgsql ||= Pgtk::Pool.new(
        Pgtk::Wire::Yaml.new(File.join(__dir__, '../target/pgsql-config.yml')),
        log: Loog::NULL
      )
      @@test_pgsql.start!
    end
    @@test_pgsql
    # rubocop:enable Style/ClassVars
  end

  private

  def test_project(login: "u#{SecureRandom.hex(8)}", title: "t#{SecureRandom.hex(8)}")
    Rsk::Projects.new(test_pgsql, login).add(title)
  end

  def test_risk(project: test_project, text: "risk #{SecureRandom.hex(8)}")
    Rsk::Risks.new(test_pgsql, project).add(text)
  end

  def test_cause(project: test_project, text: "cause #{SecureRandom.hex(8)}")
    Rsk::Causes.new(test_pgsql, project).add(text)
  end

  def test_effect(project: test_project, text: "effect #{SecureRandom.hex(8)}")
    Rsk::Effects.new(test_pgsql, project).add(text)
  end

  def test_plan(project: test_project, subject: test_risk(project: project), text: "plan #{SecureRandom.hex(8)}")
    Rsk::Plans.new(test_pgsql, project).add(subject, text)
  end

  def test_triple(project: test_project)
    Rsk::Triples.new(test_pgsql, project).add(
      test_cause(project: project),
      test_risk(project: project),
      test_effect(project: project)
    )
  end
end
