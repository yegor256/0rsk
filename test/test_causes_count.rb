# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'securerandom'
require_relative 'test__helper'

require_relative '../objects/causes'
require_relative '../objects/triples'

class Rsk::CausesCountTest < TestCase
  def test_counts_one_risk_once_whatever_the_triples
    project = test_project
    cause = test_cause(project: project)
    risk = test_risk(project: project)
    triples = Rsk::Triples.new(test_pgsql, project)
    3.times { triples.add(cause, risk, test_effect(project: project)) }
    assert_equal(
      1,
      Rsk::Causes.new(test_pgsql, project).fetch[0][:risks],
      'one risk through three triples is still one risk'
    )
  end
end
