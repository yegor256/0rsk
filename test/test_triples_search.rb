# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'json'
require 'securerandom'
require_relative 'test__helper'

require_relative '../objects/plans'
require_relative '../objects/triples'

class Rsk::TriplesSearchTest < TestCase
  def test_shows_every_plan_of_a_matching_triple
    project = test_project
    risk = test_risk(project: project)
    cause = test_cause(project: project)
    triples = Rsk::Triples.new(test_pgsql, project)
    triples.add(cause, risk, test_effect(project: project))
    plans = Rsk::Plans.new(test_pgsql, project)
    alpha = "alpha #{SecureRandom.hex(8)}"
    plans.add(risk, alpha)
    plans.add(cause, "beta #{SecureRandom.hex(8)}")
    assert_equal(2, triples.fetch[0][:plans].count, 'both plans must be there')
    assert_equal(2, triples.fetch(query: alpha)[0][:plans].count, 'a search must not hide the other plan')
  end
end
