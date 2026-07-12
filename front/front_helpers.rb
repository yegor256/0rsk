# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

helpers do
  def csrf_token
    Rack::Protection::AuthenticityToken.token(session)
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
