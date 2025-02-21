# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'
require_relative 'urror'

# Projects.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::Projects
  def initialize(pgsql, login)
    @pgsql = pgsql
    @login = login
  end

  def add(title)
    @pgsql.exec(
      'INSERT INTO project (login, title) VALUES ($1, $2) RETURNING id',
      [@login, title]
    )[0]['id'].to_i
  end

  def delete(id)
    raise Rsk::Urror, "Project ##{id} doesn't exist" unless exists?(id)
    @pgsql.exec(
      'DELETE FROM project WHERE id = $1 AND login = $2',
      [id, @login]
    )
  end

  def fetch
    @pgsql.exec('SELECT * FROM project WHERE login = $1', [@login]).map do |r|
      {
        id: r['id'].to_i,
        title: r['title'],
        created: Time.parse(r['created'])
      }
    end
  end

  def exists?(pid)
    !@pgsql.exec('SELECT * FROM project WHERE login = $1 AND id = $2', [@login, pid]).empty?
  end
end
