# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require_relative '../objects/rsk'

class Rsk::DestructiveRoutesTest < Minitest::Test
  def test_destructive_actions_are_not_get_routes
    refute_match(%r{^get '/projects/delete'}m, app)
    refute_match(%r{^get '/ranked/delete'}m, app)
    refute_match(%r{^get '/responses/detach'}m, app)
  end

  def test_destructive_actions_are_post_routes
    assert_match(%r{^post '/projects/delete'}m, app)
    assert_match(%r{^post '/ranked/delete'}m, app)
    assert_match(%r{^post '/responses/detach'}m, app)
  end

  def test_destructive_controls_use_post_forms
    controls = {
      'views/projects.haml' => '/projects/delete',
      'views/ranked.haml' => '/ranked/delete',
      'views/responses.haml' => '/responses/detach'
    }
    controls.each do |file, path|
      view = File.read(file)
      assert_match(
        /%form\{[^}]*method: 'POST'[^}]*action: iri\.cut\('#{Regexp.escape(path)}'\)/,
        view
      )
      refute_match(/%a\.item.*href: iri\.cut\('#{Regexp.escape(path)}'\)/, view)
    end
  end

  private

  def app
    File.read('0rsk.rb')
  end
end
