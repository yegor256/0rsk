# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

helpers do
  def jsonify
    halt(403) unless @locals[:user]
    content_type('application/json')
  end
end

get '/causes.json' do
  jsonify
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
  jsonify
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
  jsonify
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
  jsonify
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
  %i[ctext rtext etext cid rid eid probability impact].each do |name|
    raise(Rsk::Urror, "The #{name} is missing in the form") if params[name].nil?
  end
  ctext = params[:ctext].strip
  rtext = params[:rtext].strip
  etext = params[:etext].strip
  probability = number(params[:probability], 'probability')
  impact = number(params[:impact], 'impact')
  cid = params[:cid].empty? ? causes.add(ctext) : params[:cid]
  rid = params[:rid].empty? ? risks.add(rtext) : params[:rid]
  eid = params[:eid].empty? ? effects.add(etext) : params[:eid]
  # @todo #530:30min Save the triple in one transaction.
  #  The texts are written one statement at a time, so a value that only the
  #  object can reject still leaves them changed: a probability of 42 passes
  #  "number" here and is refused later by Risk#weigh, after all three renames
  #  have been committed. Wrapping the whole save in a single transaction would
  #  make the form atomic, but every object below takes its own connection from
  #  the pool, so this needs the connection to be threaded through first.
  causes.get(cid).decorate(params[:emoji])
  causes.get(cid).rename(ctext)
  risks.get(rid).rename(rtext)
  effects.get(eid).rename(etext)
  risks.get(rid).weigh(probability)
  effects.get(eid).weigh(impact)
  effects.get(eid).polarize(!params[:positive].nil?)
  tid = triples.add(cid, rid, eid)
  flash("/responses?id=#{tid}", "Thanks, the triple ##{tid} successfully saved!")
end
