# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'json'
require 'net/http'

require_relative 'test__helper'

require_relative '../objects/tasktracker'

class Rsk::TaskTrackerTest < TestCase
  class FakeResponse
    attr_reader :code, :message, :body

    def initialize(code, body = '')
      @code = code
      @message = 'OK'
      @body = body
    end
  end

  class FakeHTTP
    def initialize(search)
      @search = search
    end

    def request(req)
      FakeResponse.new('200', (req.is_a?(Net::HTTP::Get) ? @search : { number: 77 }.to_json))
    end
  end

  def test_creates_issue_when_not_found
    assert_equal(
      77,
      Rsk::TaskTracker.new('yegor256/0rsk', 'token').create(task, http: FakeHTTP.new({ items: [] }.to_json))
    )
  end

  def test_reuses_existing_issue
    assert_equal(
      5,
      Rsk::TaskTracker.new('yegor256/0rsk', 'token').create(
        task,
        http: FakeHTTP.new({ items: [{ number: 5 }] }.to_json)
      )
    )
  end

  def test_rejects_invalid_token
    http = Class.new do
      def request(_req)
        FakeResponse.new('401')
      end
    end.new
    tracker = Rsk::TaskTracker.new('yegor256/0rsk', 'token')
    assert_raises(Rsk::Urror) { tracker.create(task, http: http) }
  end

  def test_rejects_validation_error
    http = Class.new do
      def request(_req)
        FakeResponse.new('422', { errors: [{ message: 'oops' }] }.to_json)
      end
    end.new
    tracker = Rsk::TaskTracker.new('yegor256/0rsk', 'token')
    assert_raises(Rsk::Urror) { tracker.create(task, http: http) }
  end

  private

  def task
    {
      id: 123,
      ptext: 'solve it',
      ctext: 'we have data',
      rtext: 'we may lose it',
      etext: 'business will stop',
      schedule: '01-01-2020'
    }
  end
end
