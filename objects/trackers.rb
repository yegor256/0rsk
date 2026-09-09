# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'
require_relative 'urror'

class Rsk::Trackers
  def initialize(pgsql, project)
    @pgsql = pgsql
    @project = project
  end

  MAX = 256

  def add(repo, token)
    Integer(
      @pgsql.exec(
        'INSERT INTO tracker (project, repo, token) VALUES ($1, $2, $3) RETURNING id',
        [@project, text(repo, 'repository'), text(token, 'token')]
      )[0]['id'], 10
    )
  end

  def fetch
    @pgsql.exec('SELECT * FROM tracker WHERE project = $1 ORDER BY created', [@project]).map do |r|
      {
        id: Integer(r['id'], 10),
        type: r['type'],
        repo: r['repo'],
        created: Time.parse(r['created'])
      }
    end
  end

  def exists?(id)
    !@pgsql.exec('SELECT id FROM tracker WHERE id = $1 AND project = $2', [id, @project]).empty?
  end

  def delete(id)
    @pgsql.exec('DELETE FROM tracker WHERE id = $1 AND project = $2', [id, @project])
  end

  private

  def text(value, name)
    stripped = value.to_s.strip
    raise(Rsk::Urror, "The #{name} can't be empty") if stripped.empty?
    raise(Rsk::Urror, "The #{name} is longer than #{Rsk::Trackers::MAX}: #{stripped.length}") if
      stripped.length > Rsk::Trackers::MAX
    stripped
  end
end
