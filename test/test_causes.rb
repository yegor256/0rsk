# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'securerandom'

require_relative 'test__helper'

require_relative '../objects/causes'
require_relative '../objects/effects'
require_relative '../objects/projects'
require_relative '../objects/risks'
require_relative '../objects/rsk'
require_relative '../objects/triples'

class Rsk::CausesTest < TestCase
  def test_adds_and_fetches
    causes = Rsk::Causes.new(test_pgsql, test_project)
    text = 'we use Ruby'
    assert_equal(0, causes.count)
    cid = causes.add(text)
    assert_predicate(cid, :positive?)
    assert_equal(1, causes.count)
    assert(causes.fetch.any? { |c| c[:id] == cid })
    assert(causes.fetch.any? { |c| c[:text] == text })
  end

  def test_keeps_the_fraction_of_the_rank
    project = test_project
    causes = Rsk::Causes.new(test_pgsql, project)
    risks = Rsk::Risks.new(test_pgsql, project)
    effects = Rsk::Effects.new(test_pgsql, project)
    triples = Rsk::Triples.new(test_pgsql, project)
    high = causes.add('the higher one')
    low = causes.add('the lower one')
    [[high, 10, 9], [high, 10, 10], [low, 10, 9], [low, 10, 9]].each do |cid, probability, impact|
      rid = risks.add("risk #{SecureRandom.hex(8)}")
      risks.get(rid).weigh(probability)
      eid = effects.add("effect #{SecureRandom.hex(8)}")
      effects.get(eid).weigh(impact)
      triples.add(cid, rid, eid)
    end
    found = causes.fetch
    assert_equal(high, found[0][:id], found.map { |c| [c[:id], c[:rank]] }.inspect)
    assert_operator(found[0][:rank], :>, found[1][:rank])
  end

  def test_fetch_emojis
    causes = Rsk::Causes.new(test_pgsql, test_project)
    causes.get(causes.add('some cause')).decorate('💰')
    assert_operator(causes.emojis.count, :>, 1)
  end
end
