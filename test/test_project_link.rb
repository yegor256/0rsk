# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'securerandom'
require_relative 'test__helper'
require_relative '../0rsk'

class Rsk::ProjectLinkTest < TestCase
  def test_links_to_the_project_page
    listing = Object.new.extend(Rsk::Telegram).listing(
      [
        {
          id: 42, triple: 7, positive: true, rank: 3, text: 'Do it',
          title: 'Project', pid: 5, ctext: 'Cause', rtext: 'Risk',
          etext: 'Effect', schedule: 'weekly'
        }
      ]
    ).flatten.join(' ')
    assert_includes(listing, 'https://www.0rsk.com/project/5', listing)
  end
end
