# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

before '/*' do
  now = Time.now.to_i
  settings.rate_limits.reject! { |t| t < now - 60 }
  if request.post?
    settings.rate_limits << now
    halt 429, { 'Content-Type' => 'text/plain' }, 'Too many requests' if settings.rate_limits.size > 10
  end
  @locals = { http_start: Time.now, ver: Rsk::VERSION, login_link: settings.glogin.login_uri, request_ip: request.ip }
  response.set_cookie('glogin', params[:glogin]) if params[:glogin]
  if request.cookies['glogin']
    begin
      @locals[:user] = GLogin::Cookie::Closed.new(
        request.cookies['glogin'],
        settings.config['github']['encryption_secret'],
        context
      ).to_user
    rescue GLogin::Codec::DecodingError
      response.delete_cookie('glogin')
    end
  end
  @locals[:tasks_count] = tasks.count if @locals[:user]
end

get '/github-callback' do
  code = params[:code]
  error(400) if code.nil?
  response.set_cookie(
    :glogin, GLogin::Cookie::Open.new(
      settings.glogin.user(code),
      settings.config['github']['encryption_secret'],
      context
    ).to_s
  )
  flash('/', 'You have been logged in')
end

get '/logout' do
  response.delete_cookie('glogin')
  flash('/', 'You have been logged out')
end

post '/logout' do
  response.delete_cookie('glogin')
  flash('/', 'You have been logged out')
end
