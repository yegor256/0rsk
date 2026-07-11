# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

before '/*' do
  response.headers['Content-Security-Policy'] = [
    "default-src 'self'",
    "script-src 'self' https://code.jquery.com https://cdnjs.cloudflare.com",
    "script-src-attr 'unsafe-inline'",
    "style-src 'self' https://cdn.jsdelivr.net https://www.yegor256.com",
    "img-src 'self' https://img.shields.io https://www.sixnines.io",
    "font-src 'self' https://www.yegor256.com",
    "base-uri 'self'",
    "form-action 'self'"
  ].join('; ')
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
