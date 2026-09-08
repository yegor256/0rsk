# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'securerandom'
require_relative 'test__helper'

require_relative '../objects/causes'
require_relative '../objects/triples'

class Rsk::CausesOrderTest < TestCase
  def test_puts_a_cause_with_no_rank_last
    project = test_project
    linked = "linked #{SecureRandom.hex(8)}"
    risk = test_risk(project: project)
    Rsk::Risks.new(test_pgsql, project).get(risk).weigh(9)
    effect = test_effect(project: project)
    Rsk::Effects.new(test_pgsql, project).get(effect).weigh(9)
    Rsk::Triples.new(test_pgsql, project).add(Rsk::Causes.new(test_pgsql, project).add(linked), risk, effect)
    Rsk::Causes.new(test_pgsql, project).add("lonely #{SecureRandom.hex(8)}")
    assert_equal(linked, Rsk::Causes.new(test_pgsql, project).fetch[0][:text], 'the ranked one comes first')
  end
end
