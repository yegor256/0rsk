# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'

class Rsk::Trackers
  def initialize(pgsql, project)
    @pgsql = pgsql
    @project = project
  end

  def add(repo, token)
    @pgsql.exec(
      'INSERT INTO tracker (project, repo, token) VALUES ($1, $2, $3) RETURNING id',
      [@project, repo, token]
    )[0]['id'].to_i
  end

  def fetch
    @pgsql.exec('SELECT * FROM tracker WHERE project = $1 ORDER BY created', [@project]).map do |r|
      {
        id: r['id'].to_i,
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
end
