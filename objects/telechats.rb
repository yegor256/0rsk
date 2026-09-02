# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'

class Rsk::Telechats
  def initialize(pgsql)
    @pgsql = pgsql
  end

  def add(id, login)
    @pgsql.exec('INSERT INTO telechat (id, login) VALUES ($1, $2)', [id, login])
  end

  def exists?(id)
    !@pgsql.exec('SELECT * FROM telechat WHERE id = $1', [id]).empty?
  end

  def wired?(login)
    !@pgsql.exec('SELECT * FROM telechat WHERE login = $1', [login]).empty?
  end

  def login(id)
    row('SELECT login FROM telechat WHERE id = $1', id)['login']
  end

  def chat(login)
    Integer(row('SELECT id FROM telechat WHERE login = $1', login)['id'])
  end

  def posted(msg, chat)
    @pgsql.exec('UPDATE telechat SET recent = $1 WHERE id = $2', [msg, chat])
  end

  def diff?(msg, chat)
    row('SELECT recent FROM telechat WHERE id = $1', chat)['recent'] != msg
  end

  private

  def row(sql, key)
    found = @pgsql.exec(sql, [key]).first
    raise(Rsk::Urror, "Telegram chat is not wired: #{key}") if found.nil?
    found
  end
end
