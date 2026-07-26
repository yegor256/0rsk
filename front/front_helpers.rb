# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

helpers do
  def csrf_token
    @csrf_token ||= begin
      token = request.cookies['csrf-token']
      token = SecureRandom.hex(32) if token.to_s.empty?
      response.set_cookie('csrf-token', value: token, same_site: :lax, httponly: true)
      token
    end
  end

  def verify_csrf!
    token = params[:authenticity_token].to_s
    halt(403, 'Invalid CSRF token') if token.empty? || token != request.cookies['csrf-token'].to_s
  end

  def part(prefix, id)
    "<a href='#{iri.cut('/ranked').add(q: "+#{id}")}'><code>#{prefix}#{id}</code></a>"
  end

  def thumb(i)
    direction = i[:positive] ? 'up' : 'down'
    "<img class='#{direction}' alt='#{direction}'/>"
  end

  def rank(i)
    "<span class=''>#{Integer(i[:rank])}</span>"
  end
end
