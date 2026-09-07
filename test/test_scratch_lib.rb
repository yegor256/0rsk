require 'json'
require_relative 'test__helper'
require_relative '../0rsk'
require_relative '../objects/causes'
require_relative '../objects/effects'
require_relative '../objects/projects'
require_relative '../objects/risks'
require_relative '../objects/rsk'
require_relative '../objects/triples'
require_relative '../objects/plans'
require_relative '../objects/tasks'

module Rack
  module Test
    class Session
      def defaults
        { 'REMOTE_ADDR' => $rsk_ip || '127.0.0.1', 'HTTPS' => 'on' }.merge(headers_for_env)
      end
      alias default_env defaults
    end
  end
end

class ScratchBase < TestCase
  include Rack::Test::Methods
  def app
    Sinatra::Application
  end

  def ip!(v)
    $rsk_ip = v
    clear_cookies rescue nil
  end

  def login(name)
    set_cookie("glogin=#{name}")
  end

  def use(login, pid)
    login(login)
    set_cookie("0rsk-project=#{pid}")
  end
end
