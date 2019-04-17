# frozen_string_literal: true

# Copyright (c) 2019 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require_relative 'rsk'
require_relative 'links'
require_relative 'urror'

# Ranked.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019 Yegor Bugayenko
# License:: MIT
class Rsk::Ranked
  def initialize(pgsql, project)
    @pgsql = pgsql
    @project = project
  end

  # For example: mnemo="CR", path="C43 R89"
  def analyze(path)
    chunks = path.split(' ')
    ids = [insert(chunks)]
    links = Rsk::Links.new(@pgsql, @project)
    links.right_of(chunks.last).each do |e|
      ids += analyze((chunks + [e]).join(' '))
    end
    ids
  end

  def delete(id)
    row = @pgsql.exec('SELECT path FROM ranked WHERE id = $1 AND project = $2', [id, @project])[0]
    raise Rsk::Urror, "Ranked item ##{id} not found in project ##{@project}" if row.nil?
    path = row['path']
    chunks = path_to_chunks(path)
    return if chunks.count < 2
    a, b = chunks.last(2)
    links = Rsk::Links.new(@pgsql, @project)
    links.delete(a, b)
    @pgsql.exec('DELETE FROM ranked WHERE id = $1 AND project = $2', [id, @project])
    @pgsql.exec('SELECT id FROM ranked WHERE project = $1 AND path LIKE $2', [@project, path + ' %']).each do |r|
      delete(r['id'].to_i)
    end
  end

  def fetch(query: '', chunks: [], mnemo: '*', offset: 0, limit: 50)
    rows = @pgsql.exec(
      [
        'SELECT * FROM ranked',
        'WHERE project = $1',
        'AND LOWER(text) LIKE $4',
        'AND (' + mnemos(mnemo).map { |m| "mnemo = '#{m}'" }.join(' OR ') + ')',
        chunks.empty? ? '' : 'AND (' + chunks.map { |c| "path LIKE '%[#{c}]%'" }.join(' OR ') + ')',
        'ORDER BY rank DESC',
        'OFFSET $2 LIMIT $3'
      ].join(' '),
      [@project, offset, limit, "%#{query.strip.downcase}%"]
    )
    rows.map do |r|
      c = path_to_chunks(r['path'])
      {
        id: r['id'].to_i,
        rank: r['rank'].to_i,
        mnemo: r['mnemo'],
        path: c.join(' '),
        chunks: c,
        text: r['text'],
        created: Time.parse(r['created'])
      }
    end
  end

  private

  def path_to_chunks(path)
    path.scan(/\[([A-Z][0-9]+)\]/).map { |x| x[0] }
  end

  def insert(chunks)
    mnemo = mnemo(chunks)
    @pgsql.exec(
      [
        'INSERT INTO ranked (project, rank, mnemo, path, text)',
        'VALUES ($1, $2, $3, $4, $5)',
        'ON CONFLICT(project, path) DO UPDATE SET rank = $2, text = $5',
        'RETURNING id'
      ].join(' '),
      [@project, rank(mnemo, chunks), mnemo, chunks.map { |c| "[#{c}]" }.join(' '), text(chunks)]
    )[0]['id'].to_i
  end

  def mnemo(chunks)
    links = Rsk::Links.new(@pgsql, @project)
    chunks.map { |c| links.item(c).mnemo }.join
  end

  def mnemos(mnemo)
    if mnemo.end_with?('*')
      case mnemo
      when 'C*', '*'
        %w[C CR CP CRP CRE CREP]
      when 'CR*'
        %w[CR CRE CRP CREP]
      when 'CRE*'
        %w[CRE CREP]
      end
    else
      [mnemo]
    end
  end

  def rank(mnemo, chunks)
    return 1 unless mnemo == 'CRE'
    links = Rsk::Links.new(@pgsql, @project)
    risk = links.item(chunks[1])
    effect = links.item(chunks[2])
    risk.probability * effect.impact
  end

  def text(chunks)
    links = Rsk::Links.new(@pgsql, @project)
    chunks.map { |c| links.item(c).text }
  end
end
