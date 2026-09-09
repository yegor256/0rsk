# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'json'
require 'securerandom'
require_relative 'test__helper'

require_relative '../objects/plans'
require_relative '../objects/triples'

class Rsk::TriplesDeleteTest < TestCase
  def test_leaves_no_plan_behind
    project = test_project
    risk = test_risk(project: project)
    triples = Rsk::Triples.new(test_pgsql, project)
    plans = Rsk::Plans.new(test_pgsql, project)
    text = "plan #{SecureRandom.hex(8)}"
    plans.add(risk, text)
    triples.delete(triples.add(test_cause(project: project), risk, test_effect(project: project)))
    assert_equal(0, triples.count, 'the triple must be gone')
    assert_equal(0, plans.count(query: ''), 'the plan must be gone')
    plans.add(test_risk(project: project), text)
  end
end
