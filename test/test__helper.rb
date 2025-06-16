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
  def teardown
    truncate_all_db_tables
  end

  def test_pgsql
    # rubocop:disable Style/ClassVars
    @@test_pgsql ||= Pgtk::Pool.new(
      Pgtk::Wire::Yaml.new(File.join(__dir__, '../target/pgsql-config.yml')),
      log: Loog::NULL
    ).start
    # rubocop:enable Style/ClassVars
  end

  private

  def truncate_all_db_tables
    test_pgsql.exec <<-SQL
      -- Disable "truncate cascades to table" notice
      set client_min_messages = warning;

      DO $$
      DECLARE
          table_name TEXT;
      BEGIN
          FOR table_name IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
              EXECUTE 'TRUNCATE TABLE ' || table_name || ' RESTART IDENTITY CASCADE';
          END LOOP;
      END $$;

      -- Reset
      set client_min_messages = notice;
    SQL
  end
end
