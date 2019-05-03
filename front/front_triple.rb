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

get '/causes.json' do
  content_type('application/json')
  JSON.pretty_generate(
    causes.fetch(query: params[:query] || '').map do |r|
      {
        label: "C#{r[:id]}: #{r[:text]}",
        value: r[:text],
        fields: {
          cid: r[:id]
        }
      }
    end
  )
end

get '/risks.json' do
  content_type('application/json')
  JSON.pretty_generate(
    risks.fetch(query: params[:query] || '').map do |r|
      {
        label: "R#{r[:id]}: #{r[:text]}",
        value: r[:text],
        fields: {
          rid: r[:id],
          probability: r[:probability]
        }
      }
    end
  )
end

get '/effects.json' do
  content_type('application/json')
  JSON.pretty_generate(
    effects.fetch(query: params[:query] || '').map do |r|
      {
        label: "E#{r[:id]}: #{r[:text]}",
        value: r[:text],
        fields: {
          eid: r[:id],
          impact: r[:impact],
          positive: r[:positive]
        }
      }
    end
  )
end

get '/plans.json' do
  content_type('application/json')
  JSON.pretty_generate(
    plans.fetch(query: params[:query] || '').map do |r|
      {
        label: "P#{r[:id]}: #{r[:text]}",
        value: r[:text],
        fields: {
          pid: r[:id],
          schedule: r[:schedule]
        }
      }
    end
  )
end

get '/triple' do
  vars = { title: '/triple', project: current_project }
  id = params[:id].to_i
  if id.positive?
    triple = triples.fetch(query: id, limit: 1)[0]
    raise Rsk::Urror, "Triple ##{id} not found" if triple.nil?
    vars[:triple] = triple
  end
  haml :triple, layout: :layout, locals: merged(vars)
end

post '/triple/save' do
  ctext = params[:ctext].strip
  rtext = params[:rtext].strip
  etext = params[:etext].strip
  cid = params[:cid].empty? ? causes.add(ctext) : params[:cid]
  rid = params[:rid].empty? ? risks.add(rtext) : params[:rid]
  eid = params[:eid].empty? ? effects.add(etext) : params[:eid]
  causes.get(cid).text = ctext
  risks.get(rid).text = rtext
  effects.get(eid).text = etext
  risks.get(rid).probability = params[:probability].to_i
  effects.get(eid).impact = params[:impact].to_i
  effects.get(eid).positive = !params[:positive].nil?
  tid = triples.add(cid, rid, eid)
  flash("/responses?id=#{tid}", "Thanks, the triple ##{tid} successfully saved!")
end
