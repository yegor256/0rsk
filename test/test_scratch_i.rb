require_relative 'test_scratch_lib'
require 'securerandom'
require 'time'

class ScratchI < ScratchBase
  def setup_project(prefix)
    lg = "#{prefix}#{SecureRandom.hex(6)}"
    pj = Rsk::Projects.new(test_pgsql, lg).add("p#{SecureRandom.hex(6)}")
    c = Rsk::Causes.new(test_pgsql, pj).add("c#{SecureRandom.hex(6)}")
    r = Rsk::Risks.new(test_pgsql, pj).add("r#{SecureRandom.hex(6)}")
    e = Rsk::Effects.new(test_pgsql, pj).add("e#{SecureRandom.hex(6)}")
    t = Rsk::Triples.new(test_pgsql, pj).add(c, r, e)
    [lg, pj, c, r, e, t]
  end

  def test_time_parse_of_schedule
    %w[01-02-2026 13-01-2026 31-12-2026 05-11-2026 03-04-2026].each do |s|
      puts "Time.parse(#{s.inspect}) = #{begin; Time.parse(s).strftime('%Y-%m-%d'); rescue StandardError => e; e.class.to_s; end}  Date.strptime dd-mm-yyyy = #{Date.strptime(s, '%d-%m-%Y')}"
    end
  end

  def test_task_journey
    ip!("10.50.#{rand(250)}.#{rand(250)}")
    lg, pj, _c, r, _e, t = setup_project('ta')
    pl = Rsk::Plans.new(test_pgsql, pj)
    pid1 = pl.add(r, "onetime #{SecureRandom.hex(4)}")
    pl.get(pid1, r).reschedule('01-01-2020')
    use(lg, pj)
    post('/tasks/create')
    puts "POST /tasks/create -> #{last_response.status} #{last_response.headers['Set-Cookie'].to_s[/flash_msg=[^;]*/]}"
    rows = test_pgsql.exec('SELECT * FROM task WHERE plan=$1', [pid1])
    puts "  task rows for plan #{pid1}: #{rows.map(&:to_h).inspect}"
    tid = Integer(rows[0]['id'])
    get('/tasks')
    puts "GET /tasks (1 task) -> #{last_response.status} #{last_response.body[/undefined method[^<\\\n]*/]}"
    get('/favicon.svg')
    puts "GET /favicon.svg -> #{last_response.status} #{last_response.body[/>([^<]*)<\/text>/, 1].inspect}"
    # postpone with bad period
    post('/tasks/later', { 'id' => tid.to_s, 'period' => 'year' })
    puts "POST /tasks/later period=year -> #{last_response.status} #{last_response.headers['Set-Cookie'].to_s[/flash_msg=[^;]*/]}"
    puts "  task still there: #{!test_pgsql.exec('SELECT * FROM task WHERE id=$1', [tid]).empty?}  schedule=#{test_pgsql.exec('SELECT schedule FROM plan WHERE id=$1', [pid1])[0]['schedule']}"
    post('/tasks/later', { 'id' => tid.to_s, 'period' => 'week' })
    puts "POST /tasks/later period=week -> #{last_response.status} #{last_response.headers['Set-Cookie'].to_s[/flash_msg=[^;]*/]}"
    puts "  task gone: #{test_pgsql.exec('SELECT * FROM task WHERE id=$1', [tid]).empty?}  schedule=#{test_pgsql.exec('SELECT schedule FROM plan WHERE id=$1', [pid1])[0]['schedule']}"
    # recreate and mark done
    post('/tasks/create')
    rows = test_pgsql.exec('SELECT * FROM task WHERE plan=$1', [pid1])
    puts "  after re-create, task rows: #{rows.size} (expected 0, schedule is in the future)"
    # word-scheduled plan
    pid2 = pl.add(r, "recurring #{SecureRandom.hex(4)}")
    pl.get(pid2, r).reschedule('daily')
    test_pgsql.exec('UPDATE plan SET completed = $2 WHERE id = $1', [pid2, Time.now - (10 * 24 * 60 * 60)])
    post('/tasks/create')
    rows2 = test_pgsql.exec('SELECT * FROM task WHERE plan=$1', [pid2])
    puts "  daily plan task created: #{rows2.size}"
    t2 = Integer(rows2[0]['id'])
    post('/tasks/done', { 'id' => t2.to_s })
    puts "POST /tasks/done (daily) -> #{last_response.status} plan still exists=#{!test_pgsql.exec('SELECT * FROM plan WHERE id=$1', [pid2]).empty?} completed=#{test_pgsql.exec('SELECT completed FROM plan WHERE id=$1', [pid2])[0]&.fetch('completed')}"
    # done on a one-off plan
    pid3 = pl.add(r, "oneoff2 #{SecureRandom.hex(4)}")
    pl.get(pid3, r).reschedule('01-01-2020')
    post('/tasks/create')
    rows3 = test_pgsql.exec('SELECT * FROM task WHERE plan=$1', [pid3])
    t3 = Integer(rows3[0]['id'])
    post('/tasks/done', { 'id' => t3.to_s })
    puts "POST /tasks/done (one-off) -> #{last_response.status} plan row exists=#{!test_pgsql.exec('SELECT * FROM plan WHERE id=$1', [pid3]).empty?} part row exists=#{!test_pgsql.exec('SELECT * FROM part WHERE id=$1', [pid3]).empty?}"
    puts "  triple #{t} still exists: #{!test_pgsql.exec('SELECT * FROM triple WHERE id=$1', [t]).empty?}"
  end
end
