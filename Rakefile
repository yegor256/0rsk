# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'rubygems'
require 'rake'
require 'rdoc'
require 'rake/clean'

ENV['RACK_ENV'] = 'test'

task default: %i[clean test eslint rubocop xcop]

require 'rake/testtask'
Rake::TestTask.new(test: %i[pgsql liquibase]) do |test|
  Rake::Cleaner.cleanup_files(['coverage'])
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
  test.warning = true
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.fail_on_error = true
end

require 'eslintrb/eslinttask'
Eslintrb::EslintTask.new(:eslint) do |t|
  t.pattern = 'js/**/*.js'
  t.options = :defaults
end

require 'pgtk/pgsql_task'
Pgtk::PgsqlTask.new(:pgsql) do |t|
  t.quiet = true
  t.dir = 'target/pgsql'
  t.fresh_start = true
  t.user = 'test'
  t.password = 'test'
  t.dbname = 'test'
  t.yaml = 'target/pgsql-config.yml'
end

require 'pgtk/liquibase_task'
Pgtk::LiquibaseTask.new(:liquibase) do |t|
  t.quiet = true
  t.master = 'liquibase/master.xml'
  t.yaml = ['target/pgsql-config.yml', 'config.yml']
end

require 'xcop/rake_task'
Xcop::RakeTask.new(:xcop) do |task|
  task.includes = ['**/*.xml', '**/*.xsl', '**/*.xsd', '**/*.html']
  task.excludes = ['target/**/*', 'coverage/**/*', 'vendor/**/*']
end

desc 'Check the quality of config file'
task(:config) do
  YAML.safe_load(File.open('config.yml')).to_yaml
end

desc 'Load sample data for development/demo'
task(seed_dummy: %i[pgsql liquibase]) do
  require 'yaml'
  require 'loog'
  require 'pgtk/pool'
  require_relative 'objects/rsk'
  require_relative 'objects/projects'
  require_relative 'objects/causes'
  require_relative 'objects/risks'
  require_relative 'objects/effects'
  require_relative 'objects/triples'
  require_relative 'objects/plans'
  pgsql = Pgtk::Pool.new(
    Pgtk::Wire::Yaml.new('target/pgsql-config.yml'),
    log: Loog::NULL
  ).start
  fixtures = YAML.safe_load(File.read('liquibase/fixtures.yml'))
  fixtures.each do |key, data|
    login = "demo_#{key}"
    pid = Rsk::Projects.new(pgsql, login).add(data['title'])
    causes = Rsk::Causes.new(pgsql, pid)
    risks = Rsk::Risks.new(pgsql, pid)
    effects = Rsk::Effects.new(pgsql, pid)
    triples = Rsk::Triples.new(pgsql, pid)
    plans = Rsk::Plans.new(pgsql, pid)
    cids = data['causes'].map { |c| causes.add(c['text']) }
    rids = data['risks'].map { |r| risks.add(r['text']) }
    eids = data['effects'].map { |e| effects.add(e['text']) }
    data['plans'].each do |p|
      ci = cids[data['causes'].index { |c| c['text'] == p['cause'] }]
      ri = rids[data['risks'].index { |r| r['text'] == p['risk'] }]
      ei = eids[data['effects'].index { |e| e['text'] == p['effect'] }]
      next unless ci && ri && ei
      tid = triples.add(ci, ri, ei)
      plans.add(tid, p['text'])
    end
    puts "Seeded: #{data['title']}"
  end
  puts 'Done. Login with ?glogin=demo_mobile or ?glogin=demo_cloud'
end

task(run: %i[pgsql liquibase]) do
  `rerun -b "RACK_ENV=test rackup"`
end
