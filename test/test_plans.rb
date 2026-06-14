# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../objects/rsk'
require_relative '../objects/plans'
require_relative '../objects/projects'
require_relative '../objects/risks'

# Test of Plans.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2026 Yegor Bugayenko
# License:: MIT
class Rsk::PlansTest < Minitest::Test
  def test_adds_and_fetches
    pid = Rsk::Projects.new(test_pgsql, 'jeff23').add("test#{rand(99_999)}")
    risks = Rsk::Risks.new(test_pgsql, pid)
    rid = risks.add('we may lose data')
    plans = Rsk::Plans.new(test_pgsql, pid)
    text = 'we make backups'
    id = plans.add(rid, text)
    plans.get(id, rid).schedule = '01-01-2001'
    assert_predicate(id, :positive?)
    assert_equal(1, plans.count)
    refute_empty(plans.fetch)
    assert(plans.fetch.any? { |p| p[:text] == text })
    plans.get(id, rid).complete
  end

  def test_reports_missing_plan_part
    err = assert_raises(Rsk::Urror) do
      Rsk::Plan.new(fake_pool({ 'SELECT project FROM part WHERE id = $1 FOR UPDATE' => [] }), 17, 23).detach
    end
    assert_equal('Plan part #17 not found', err.message)
  end

  def test_finds_project_inside_transaction
    calls = []
    Rsk::Plan.new(
      fake_pool(
        {
          'SELECT project FROM part WHERE id = $1 FOR UPDATE' => [{ 'project' => '42' }],
          'SELECT * FROM part WHERE id = $1 AND project = $2' => [{}],
          'DELETE FROM plan WHERE id = $1 AND part = $2' => [],
          'SELECT * FROM plan WHERE id = $1' => [{}]
        },
        calls: calls
      ),
      17,
      23
    ).detach
    assert_includes(
      calls,
      ['SELECT project FROM part WHERE id = $1 FOR UPDATE', [17]]
    )
    assert_includes(
      calls,
      ['SELECT * FROM part WHERE id = $1 AND project = $2', [23, 42]]
    )
  end

  private

  def fake_pool(responses, calls: [])
    tx = Object.new
    tx.define_singleton_method(:exec) do |sql, args|
      calls << [sql, args]
      raise "Unexpected SQL: #{sql}" unless responses.key?(sql)
      responses[sql]
    end
    pool = Object.new
    pool.define_singleton_method(:transaction) { |&block| block.call(tx) }
    pool.define_singleton_method(:exec) { |_sql, _args| raise 'Query escaped the transaction' }
    pool
  end
end
