# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
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
require 'minitest/reporters'
Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]

require 'loog'
require 'pgtk/pool'
require 'yaml'

class Minitest::Test
  def test_pgsql
    # rubocop:disable Style/ClassVars
    # https://github.com/yegor256/0rsk/issues/171
    @@test_pgsql ||= if File.exist?('../target/pgsql-config.yml')
                       Pgtk::Pool.new(
                         Pgtk::Wire::Yaml.new('../target/pgsql-config.yml'),
                         log: Loog::NULL
                       )
                     else
                       Pgtk::Pool.new(
                         Pgtk::Wire::Env.new('TEST_DATABASE_URL'),
      log: Loog::NULL
                       )
                     end.start
    # rubocop:enable Style/ClassVars
  end
end
