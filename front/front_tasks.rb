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
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require_relative '../objects/tasks'
require_relative '../objects/daemon'

Rsk::Daemon.new(10).start do
  users.fetch.each do |login|
    tasks(login: login).create
  end
  @tasks_updated = Time.now
end

get '/tasks' do
  offset = [(params[:offset] || '0').to_i, 0].max
  limit = (params[:limit] || '10').to_i
  query = params[:q] || ''
  haml :tasks, layout: :layout, locals: merged(
    title: '/tasks',
    offset: offset,
    limit: limit,
    query: query,
    total: tasks.count,
    tasks: tasks.fetch(query: query, offset: offset, limit: limit),
    wired: telechats.wired?(current_user),
    updated: @tasks_updated
  )
end

get '/tasks/done' do
  id = params[:id].to_i
  tasks.done(id)
  flash('/tasks', "Thanks, task ##{id} was completed!")
end

get '/tasks/create' do
  tasks.create
  flash('/tasks', 'All necessary tasks were created, thanks!')
end

def tasks(login: current_user)
  Rsk::Tasks.new(settings.pgsql, login)
end
