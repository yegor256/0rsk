# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'
require_relative 'urror'

class Rsk::Plan
  attr_reader :id, :part

  def initialize(pgsql, id, part)
    @pgsql = pgsql
    @id = id
    @part = part
  end

  def detach
    @pgsql.transaction do |t|
      if t.exec('SELECT * FROM part WHERE id = $1 AND project = $2', [@part, pid]).empty?
        raise(Rsk::Urror, "##{@id} is not in your project ##{pid}")
      end
      t.exec('DELETE FROM plan WHERE id = $1 AND part = $2', [@id, @part])
      t.exec('DELETE FROM part WHERE id = $1', [@id]) if t.exec('SELECT * FROM plan WHERE id = $1', [@id]).empty?
    end
  end

  def complete(time: Time.now - (4 * 60 * 60))
    if /^[a-z]+$/.match?(schedule)
      @pgsql.exec('UPDATE plan SET completed = $3 WHERE id = $1 AND part = $2', [@id, @part, time])
    else
      detach
    end
  end

  def schedule
    @pgsql.exec('SELECT schedule FROM plan WHERE id = $1 AND part = $2', [@id, @part])[0]['schedule']
  end

  def reschedule(text)
    unless /^(daily|weekly|biweekly|monthly|quarterly|annually|\d{2}-\d{2}-\d{4})$/.match?(text)
      raise(Rsk::Urror, "Schedule can either be a word or a date DD-MM-YYYY: #{text.inspect}")
    end
    @pgsql.exec('UPDATE plan SET schedule = $3 WHERE id = $1 AND part = $2', [@id, @part, text])
  end

  private

  def pid
    Integer(@pgsql.exec('SELECT project FROM part WHERE id = $1', [@id])[0]['project'])
  end
end
