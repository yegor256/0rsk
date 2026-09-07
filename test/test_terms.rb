# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'rack/test'
require_relative 'test__helper'

require_relative '../0rsk'

class Rsk::TermsTest < TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_links_to_the_mailbox
    get('/terms')
    assert_predicate(last_response, :ok?, last_response.body)
    assert_includes(last_response.body, 'mailto:terms@0rsk.com', last_response.body)
  end
end
