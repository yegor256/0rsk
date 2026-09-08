# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'securerandom'
require_relative 'rsk'
require_relative 'urror'

class Rsk::Telechats
  HOURS = 24

  def initialize(pgsql)
    @pgsql = pgsql
  end

  def add(id, login)
    @pgsql.exec('INSERT INTO telechat (id, login) VALUES ($1, $2)', [id, login])
  end

  def invite(chat)
    token = SecureRandom.uuid
    @pgsql.transaction do |t|
      t.exec("DELETE FROM teleinvite WHERE created < NOW() - INTERVAL '#{Rsk::Telechats::HOURS} hours'")
      t.exec('INSERT INTO teleinvite (token, chat) VALUES ($1, $2)', [token, chat])
    end
    token
  end

  def accept(token, login)
    @pgsql.transaction do |t|
      rows = t.exec(
        [
          'DELETE FROM teleinvite WHERE token = $1',
          "AND created > NOW() - INTERVAL '#{Rsk::Telechats::HOURS} hours'",
          'RETURNING chat'
        ],
        [token]
      )
      raise(Rsk::Urror, 'This link is not valid any more, ask the bot for a new one') if rows.empty?
      chat = Integer(rows[0]['chat'])
      t.exec('INSERT INTO telechat (id, login) VALUES ($1, $2)', [chat, login])
      chat
    end
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
