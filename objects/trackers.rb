# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'
require_relative 'urror'

class Rsk::Trackers
  REPO_PATTERN = %r{\A[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+\z}.freeze

  def initialize(pgsql, project)
    @pgsql = pgsql
    @project = project
  end

  def add(repo, token, type: 'github')
    raise(Rsk::Urror, 'Repository must be in owner/name format') unless REPO_PATTERN.match?(repo)
    raise(Rsk::Urror, 'Token must not be empty') if token.nil? || token.empty?
    Integer(
      @pgsql.exec(
        'INSERT INTO tracker (project, repo, token, type) VALUES ($1, $2, $3, $4) RETURNING id',
        [@project, repo, token, type]
      )[0]['id'], 10
    )
  end

  def fetch(token: false)
    @pgsql.exec('SELECT * FROM tracker WHERE project = $1 ORDER BY created', [@project]).map do |r|
      h = { id: Integer(r['id'], 10), type: r['type'], repo: r['repo'], created: Time.parse(r['created']) }
      h[:token] = r['token'] if token
      h
    end
  end

  def exists?(id)
    !@pgsql.exec('SELECT id FROM tracker WHERE id = $1 AND project = $2', [id, @project]).empty?
  end

  def delete(id)
    @pgsql.exec('DELETE FROM tracker WHERE id = $1 AND project = $2', [id, @project])
  end
end
