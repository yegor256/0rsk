# frozen_string_literal: true

# Copyright (c) 2019-2025 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'minitest/autorun'
require 'rack/test'
require_relative 'test__helper'
require_relative '../0rsk'
require_relative '../objects/rsk'
require_relative '../objects/projects'

module Rack
  module Test
    class Session
      def default_env
        { 'REMOTE_ADDR' => '127.0.0.1', 'HTTPS' => 'on' }.merge(headers_for_env)
      end
    end
  end
end

class Rsk::AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_renders_pages
    pages = [
      '/version',
      '/robots.txt',
      '/',
      '/js/triple.js',
      '/js/responses.js',
      '/terms'
    ]
    pages.each do |p|
      get(p)
      assert(last_response.ok?, last_response.body)
    end
  end

  def test_not_found
    ['/unknown_path', '/js/x/y/z/not-found.js', '/css/a/b/c/not-found.css'].each do |p|
      get(p)
      assert_equal(404, last_response.status, last_response.body)
      assert_equal('text/html;charset=utf-8', last_response.content_type)
    end
  end

  def test_200_user_pages
    name = 'bill'
    login(name)
    pages = [
      '/projects',
      '/ranked',
      '/tasks',
      '/triple',
      '/risks',
      '/causes',
      '/effects',
      '/plans',
      '/causes.json',
      '/risks.json',
      '/effects.json',
      '/plans.json'
    ]
    pages.each do |p|
      get(p)
      assert_equal(200, last_response.status, "#{p} fails: #{last_response.body}")
    end
  end

  def test_add
    name = "jeff09#{rand(99_999)}"
    login(name)
    post(
      '/triple/save',
      [
        'ctext=test+cause',
        'rtext=test+risk',
        'probability=5',
        'emoji=A',
        'etext=test+effect',
        'impact=5',
        'cid=',
        'rid=',
        'eid='
      ].join('&')
    )
    assert_equal(302, last_response.status, last_response.body)
    get('/ranked')
    assert_equal(200, last_response.status, last_response.body)
  end

  private

  def login(name)
    set_cookie("glogin=#{name}")
    projects = Rsk::Projects.new(test_pgsql, name)
    pid = projects.add('test')
    set_cookie("0rsk-project=#{pid}")
  end
end
