# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'shellwords'
require_relative 'test__helper'

class Rsk::TelegramRequiresTest < TestCase
  def test_loads_the_classes_the_alone_daemon_needs
    assert_equal(
      'constant,constant',
      `#{Shellwords.escape(RbConfig.ruby)} -e #{Shellwords.escape(
        "require '#{File.expand_path('..', __dir__)}/0rsk'; " \
        "print [defined?(Rsk::Projects), defined?(Rsk::Triples)].join(',')"
      )} 2>/dev/null`,
      'both classes must be loaded before any request is served'
    )
  end
end
