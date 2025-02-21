# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

helpers do
  def part(prefix, id)
    "<a href='#{iri.cut('/ranked').add(q: "+#{id}")}'><code>#{prefix}#{id}</code></a>"
  end

  def thumb(i)
    "<img class='#{i[:positive] ? 'up' : 'down'}'/>"
  end

  def rank(i)
    rank = i[:rank].to_i
    css = ''
    css = 'red' if rank >= 64
    css = 'green' if rank <= 32
    "<span class='#{css}'>#{rank}</span>"
  end
end
