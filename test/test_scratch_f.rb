require_relative 'test_scratch_lib'
require 'securerandom'

class ScratchF < ScratchBase
  def mk(prefix)
    lg = "#{prefix}#{SecureRandom.hex(6)}"
    pj = Rsk::Projects.new(test_pgsql, lg).add("p#{SecureRandom.hex(6)}")
    c = Rsk::Causes.new(test_pgsql, pj).add("c#{SecureRandom.hex(6)}")
    r = Rsk::Risks.new(test_pgsql, pj).add("r#{SecureRandom.hex(6)}")
    e = Rsk::Effects.new(test_pgsql, pj).add("e#{SecureRandom.hex(6)}")
    t = Rsk::Triples.new(test_pgsql, pj).add(c, r, e)
    { login: lg, pid: pj, c: c, r: r, e: e, t: t }
  end

  def test_cross_user_sweep
    ip!("10.20.#{rand(250)}.#{rand(250)}")
    a = mk('xa')
    b = mk('xb')
    bplan = Rsk::Plans.new(test_pgsql, b[:pid]).add(b[:r], "bp#{SecureRandom.hex(4)}")
    Rsk::Plans.new(test_pgsql, b[:pid]).get(bplan, b[:r]).reschedule('01-01-2020')
    Rsk::Tasks.new(test_pgsql, b[:login]).create
    btask = test_pgsql.exec('SELECT id FROM task WHERE plan=$1', [bplan])[0]
    btask = btask && Integer(btask['id'])
    puts "B: pid=#{b[:pid]} triple=#{b[:t]} plan=#{bplan} part=#{b[:r]} task=#{btask.inspect}"
    use(a[:login], a[:pid])
    get("/triple?id=#{b[:t]}")
    puts "GET  /triple?id=B      -> #{last_response.status} #{last_response.headers['Set-Cookie'].to_s[/flash_msg=[^;]*/]}"
    get("/responses?id=#{b[:t]}")
    puts "GET  /responses?id=B   -> #{last_response.status} #{last_response.headers['Set-Cookie'].to_s[/flash_msg=[^;]*/]}"
    get("/project/#{b[:pid]}")
    puts "GET  /project/B        -> #{last_response.status} #{last_response.headers['Set-Cookie'].to_s[/flash_msg=[^;]*/]}"
    post('/ranked/delete', { 'id' => b[:t].to_s })
    puts "POST /ranked/delete B  -> #{last_response.status} #{last_response.headers['Set-Cookie'].to_s[/flash_msg=[^;]*/]}"
    puts "     B triple still there: #{!test_pgsql.exec('SELECT * FROM triple WHERE id=$1', [b[:t]]).empty?}"
    post('/projects/delete', { 'id' => b[:pid].to_s })
    puts "POST /projects/delete B-> #{last_response.status} #{last_response.headers['Set-Cookie'].to_s[/flash_msg=[^;]*/]}"
    puts "     B project still there: #{!test_pgsql.exec('SELECT * FROM project WHERE id=$1', [b[:pid]]).empty?}"
    post("/project/#{b[:pid]}/tracker/add", { 'repo' => 'x/y', 'token' => 'tk' })
    puts "POST /project/B/tracker/add -> #{last_response.status} #{last_response.headers['Set-Cookie'].to_s[/flash_msg=[^;]*/]}"
    if btask
      post('/tasks/done', { 'id' => btask.to_s })
      puts "POST /tasks/done B     -> #{last_response.status} #{last_response.headers['Set-Cookie'].to_s[/flash_msg=[^;]*/]}"
      puts "     B task still there: #{!test_pgsql.exec('SELECT * FROM task WHERE id=$1', [btask]).empty?}"
      post('/tasks/later', { 'id' => btask.to_s, 'period' => 'week' })
      puts "POST /tasks/later B    -> #{last_response.status} #{last_response.headers['Set-Cookie'].to_s[/flash_msg=[^;]*/]}"
      puts "     B task still there: #{!test_pgsql.exec('SELECT * FROM task WHERE id=$1', [btask]).empty?}"
    end
    post('/projects/select', { 'id' => b[:pid].to_s })
    puts "POST /projects/select B-> #{last_response.status}"
    get('/causes')
    puts "GET  /causes after select B -> #{last_response.status} #{last_response.headers['Set-Cookie'].to_s[/flash_msg=[^;]*/]}"
    # triple/save with B's part ids
    post('/triple/save', { 'ctext' => 'x', 'rtext' => 'y', 'etext' => 'z',
                           'cid' => b[:c].to_s, 'rid' => b[:r].to_s, 'eid' => b[:e].to_s,
                           'probability' => '5', 'impact' => '5', 'emoji' => 'x' })
    puts "POST /triple/save B ids-> #{last_response.status} #{last_response.headers['Set-Cookie'].to_s[/flash_msg=[^;]*/]}"
    puts "     B cause text now: #{test_pgsql.exec('SELECT text FROM part WHERE id=$1', [b[:c]])[0]['text']}"
  end
end
