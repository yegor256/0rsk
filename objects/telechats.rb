# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'

# Telechats.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::Telechats
  def initialize(pgsql)
    @pgsql = pgsql
  end

  def add(id, login)
    @pgsql.exec(
      'INSERT INTO telechat (id, login) VALUES ($1, $2)',
      [id, login]
    )
  end

  def exists?(id)
    !@pgsql.exec('SELECT * FROM telechat WHERE id = $1', [id]).empty?
  end

  def wired?(login)
    !@pgsql.exec('SELECT * FROM telechat WHERE login = $1', [login]).empty?
  end

  def login_of(id)
    @pgsql.exec('SELECT login FROM telechat WHERE id = $1', [id])[0]['login']
  end

  def chat_of(login)
    @pgsql.exec('SELECT id FROM telechat WHERE login = $1', [login])[0]['id'].to_i
  end

  # This message was just posted.
  def posted(msg, chat)
    @pgsql.exec('UPDATE telechat SET recent = $1 WHERE id = $2', [msg, chat])
  end

  # This message is different from the last posted?
  def diff?(msg, chat)
    @pgsql.exec('SELECT recent FROM telechat WHERE id = $1', [chat])[0]['recent'] != msg
  end
end
