# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'date'
require_relative 'rsk'
require_relative 'urror'

class Rsk::Plan
  attr_reader :id, :part

  def initialize(pgsql, id, part)
    @pgsql = pgsql
    @id = id
    @part = part
  end

  def detach(con: nil)
    return detach_in(con) unless con.nil?
    @pgsql.transaction do |t|
      detach_in(t)
    end
  end

  def complete(time: Time.now - (4 * 60 * 60), con: nil)
    if /^[a-z]+$/.match?(schedule(con:))
      (con || @pgsql).exec('UPDATE plan SET completed = $3 WHERE id = $1 AND part = $2', [@id, @part, time])
    else
      detach(con:)
    end
  end

  def schedule(con: nil)
    (con || @pgsql).exec('SELECT schedule FROM plan WHERE id = $1 AND part = $2', [@id, @part])[0]['schedule']
  end

  def reschedule(text, con: nil)
    unless /^(daily|weekly|biweekly|monthly|quarterly|annually|\d{2}-\d{2}-\d{4})$/.match?(text)
      raise(Rsk::Urror, "Schedule can either be a word or a date DD-MM-YYYY: #{text.inspect}")
    end
    if /^\d{2}-\d{2}-\d{4}$/.match?(text)
      begin
        Date.strptime(text, '%d-%m-%Y')
      rescue Date::Error
        raise(Rsk::Urror, "There is no such date in the calendar: #{text.inspect}")
      end
    end
    (con || @pgsql).exec('UPDATE plan SET schedule = $3 WHERE id = $1 AND part = $2', [@id, @part, text])
  end

  private

  def detach_in(con)
    project = pid(con)
    if con.exec('SELECT * FROM part WHERE id = $1 AND project = $2', [@part, project]).empty?
      raise(Rsk::Urror, "##{@id} is not in your project ##{project}")
    end
    con.exec('DELETE FROM plan WHERE id = $1 AND part = $2', [@id, @part])
    return unless con.exec('SELECT * FROM plan WHERE id = $1', [@id]).empty?
    con.exec('DELETE FROM part WHERE id = $1', [@id])
  end

  def pid(con)
    row = con.exec('SELECT project FROM part WHERE id = $1 FOR UPDATE', [@id]).first
    raise(Rsk::Urror, "Part ##{@id} is not there") if row.nil?
    Integer(row['project'])
  end
end
