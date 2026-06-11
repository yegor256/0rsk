# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'

<<<<<<< HEAD
=======
# Trackers.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2026 Yegor Bugayenko
# License:: MIT
>>>>>>> 62b5c98 (#21: add tracker table, model, and UI for GitHub integration)
class Rsk::Trackers
  def initialize(pgsql, project)
    @pgsql = pgsql
    @project = project
  end

  def add(repo, token)
<<<<<<< HEAD
    Integer(
      @pgsql.exec(
        'INSERT INTO tracker (project, repo, token) VALUES ($1, $2, $3) RETURNING id',
        [@project, repo, token]
      )[0]['id'], 10
    )
=======
    @pgsql.exec(
      'INSERT INTO tracker (project, repo, token) VALUES ($1, $2, $3) RETURNING id',
      [@project, repo, token]
    )[0]['id'].to_i
>>>>>>> 62b5c98 (#21: add tracker table, model, and UI for GitHub integration)
  end

  def fetch
    @pgsql.exec('SELECT * FROM tracker WHERE project = $1 ORDER BY created', [@project]).map do |r|
      {
<<<<<<< HEAD
        id: Integer(r['id'], 10),
=======
        id: r['id'].to_i,
>>>>>>> 62b5c98 (#21: add tracker table, model, and UI for GitHub integration)
        type: r['type'],
        repo: r['repo'],
        created: Time.parse(r['created'])
      }
    end
  end

  def exists?(id)
<<<<<<< HEAD
    !@pgsql.exec('SELECT id FROM tracker WHERE id = $1 AND project = $2', [id, @project]).empty?
  end

  def delete(id)
    @pgsql.exec('DELETE FROM tracker WHERE id = $1 AND project = $2', [id, @project])
=======
    !@pgsql.exec(
      'SELECT id FROM tracker WHERE id = $1 AND project = $2', [id, @project]
    ).empty?
  end

  def delete(id)
    @pgsql.exec(
      'DELETE FROM tracker WHERE id = $1 AND project = $2', [id, @project]
    )
>>>>>>> 62b5c98 (#21: add tracker table, model, and UI for GitHub integration)
  end
end
