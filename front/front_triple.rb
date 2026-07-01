# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

def json_endpoint
  halt 403 unless @locals[:user]
  content_type('application/json')
end

get '/causes.json' do
  json_endpoint
  JSON.pretty_generate(
    causes.fetch(query: params[:query] || '').map do |r|
      {
        label: "C#{r[:id]}: #{r[:text]}",
        value: r[:text],
        fields: {
          cid: r[:id],
          emoji: r[:emoji]
        }
      }
    end
  )
end

get '/risks.json' do
  json_endpoint
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
  json_endpoint
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
  json_endpoint
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
  vars = { title: '/triple', project: pid, emojis: causes.emojis }
  id = Integer(params[:id] || 0)
  if id.positive?
    triple = triples.fetch(id: id, limit: 1)[0]
    raise(Rsk::Urror, "Triple ##{id} not found") if triple.nil?
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
  causes.get(cid).rename(ctext)
  causes.get(cid).decorate(params[:emoji])
  risks.get(rid).rename(rtext)
  effects.get(eid).rename(etext)
  risks.get(rid).weigh(Integer(params[:probability]))
  effects.get(eid).weigh(Integer(params[:impact]))
  effects.get(eid).polarize(!params[:positive].nil?)
  tid = triples.add(cid, rid, eid)
  flash("/responses?id=#{tid}", "Thanks, the triple ##{tid} successfully saved!")
end
