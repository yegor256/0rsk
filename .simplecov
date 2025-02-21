#
# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

SimpleCov.formatter = if Gem.win_platform?
                        SimpleCov::Formatter::MultiFormatter[
                          SimpleCov::Formatter::HTMLFormatter
                        ]
                      else
                        SimpleCov::Formatter::MultiFormatter.new(
                          [SimpleCov::Formatter::HTMLFormatter]
                        )
                      end
SimpleCov.start do
  add_filter '/test/'
  add_filter '/liquibase/'
  add_filter '/views/' # haml is not supported
  minimum_coverage 30 if ENV['RACK_ENV'] == 'test'
end
