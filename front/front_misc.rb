# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

get '/js/*.js' do
  file = "#{File.join('js', params[:splat].first)}.js"
  error(404, "File not found: #{file}") unless File.exist?(file)
  content_type 'application/javascript'
  File.read(file)
end

get '/robots.txt' do
  content_type 'text/plain'
  "User-agent: *\nDisallow: /"
end

get '/version' do
  content_type 'text/plain'
  Rsk::VERSION
end

not_found do
  status :not_found
  content_type 'text/html', charset: 'utf-8'
  haml :not_found, layout: :layout, locals: merged(
    title: request.url
  )
end

error do
  status :service_unavailable
  e = env['sinatra.error']
  if e.is_a?(Rsk::Urror)
    flash(@locals[:user] ? '/ranked' : '/', e.message, color: 'darkred')
  else
    Sentry.capture_exception(e)
    haml(
      :error,
      layout: :layout,
      locals: merged(
        title: 'error',
        error: "#{e.message}\n\t#{e.backtrace.join("\n\t")}"
      )
    )
  end
end

def context
  "#{request.ip} #{request.user_agent} #{Rsk::VERSION} #{Time.now.strftime('%Y/%m')}"
end

def merged(hash)
  out = @locals.merge(hash)
  out[:local_assigns] = out
  if cookies[:flash_msg]
    out[:flash_msg] = cookies[:flash_msg]
    cookies.delete(:flash_msg)
  end
  out[:flash_color] = cookies[:flash_color] || 'darkgreen'
  cookies.delete(:flash_color)
  out
end

def flash(uri, msg = '', color: 'darkgreen')
  cookies[:flash_msg] = msg
  cookies[:flash_color] = color
  redirect(uri)
end
