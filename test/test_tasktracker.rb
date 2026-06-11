# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../objects/rsk'
require_relative '../objects/urror'
require_relative '../objects/tasktracker'
require 'json'

# rubocop:disable Naming/VariableNumber
class Rsk::TaskTrackerTest < Minitest::Test
  def test_creates_issue
    tracker = Rsk::TaskTracker.new('owner/repo', 'valid_token')
    result = tracker.create(task_data, http: success_http(42))
    assert_equal(42, result)
  end

  def test_handles_401
    tracker = Rsk::TaskTracker.new('owner/repo', 'bad_token')
    e = assert_raises(Rsk::Urror) do
      tracker.create(task_data, http: response_http(401, '{}'))
    end
    assert_match(/invalid token/, e.message)
  end

  def test_handles_404
    tracker = Rsk::TaskTracker.new('owner/missing', 'token')
    e = assert_raises(Rsk::Urror) do
      tracker.create(task_data, http: response_http(404, '{}'))
    end
    assert_match(/not found/, e.message)
  end

  def test_handles_422
    tracker = Rsk::TaskTracker.new('owner/repo', 'token')
    body = '{"errors":[{"message":"No commits"}],"message":"Validation Failed"}'
    e = assert_raises(Rsk::Urror) do
      tracker.create(task_data, http: response_http(422, body))
    end
    assert_match(/No commits/, e.message)
  end

  def test_handles_timeout
    tracker = Rsk::TaskTracker.new('owner/repo', 'token')
    http = dummy_http
    http.define_singleton_method(:request) { |_| raise Net::ReadTimeout, 'timed out' }
    e = assert_raises(Rsk::Urror) do
      tracker.create(task_data, http: http)
    end
    assert_match(/timeout/, e.message)
  end

  private

  def task_data
    {
      ctext: 'we have data',
      rtext: 'we may lose it',
      etext: 'business will stop',
      ptext: 'fix it now',
      schedule: '01-01-2025'
    }
  end

  def success_http(issue_number)
    http = dummy_http
    response = dummy_response('201', %({"number":#{issue_number}}))
    http.define_singleton_method(:request) { |_| response }
    http
  end

  def response_http(status_code, body)
    http = dummy_http
    response = dummy_response(status_code.to_s, body)
    response.define_singleton_method(:message) { 'error' }
    http.define_singleton_method(:request) { |_| response }
    http
  end

  def dummy_http
    http = Object.new
    http.define_singleton_method(:use_ssl=) { |_| true }
    http.define_singleton_method(:open_timeout=) { |_| true }
    http.define_singleton_method(:read_timeout=) { |_| true }
    http
  end

  def dummy_response(code, body)
    res = Object.new
    res.define_singleton_method(:code) { code }
    res.define_singleton_method(:body) { body }
    res
  end
end
# rubocop:enable Naming/VariableNumber
