# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require 'pgtk/pool'
require 'securerandom'
require_relative 'test__helper'

require_relative '../objects/causes'
require_relative '../objects/projects'

class Rsk::CausesConnectionTest < TestCase
  def test_keeps_the_connection_after_a_duplicate
    pool = Pgtk::Pool.new(
      Pgtk::Wire::Yaml.new(File.join(__dir__, '../target/pgsql-config.yml')), log: Loog::NULL, max: 1
    )
    pool.start!
    causes = Rsk::Causes.new(pool, Rsk::Projects.new(pool, "u#{SecureRandom.hex(8)}").add("p#{SecureRandom.hex(8)}"))
    text = "cause #{SecureRandom.hex(8)}"
    causes.add(text)
    backends = []
    5.times do
      assert_raises(Rsk::Urror) { causes.add(text) }
      backends << pool.exec('SELECT pg_backend_pid() AS p')[0]['p']
    end
    assert_equal(1, backends.uniq.size, "a refused duplicate must not throw the connection away: #{backends}")
  end
end
