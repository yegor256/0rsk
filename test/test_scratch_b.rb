require_relative 'test_scratch_lib'
require 'securerandom'

class ScratchB < ScratchBase
  def mk(prefix)
    lg = "#{prefix}#{SecureRandom.hex(6)}"
    pj = Rsk::Projects.new(test_pgsql, lg).add("p#{SecureRandom.hex(6)}")
    c = Rsk::Causes.new(test_pgsql, pj).add("c#{SecureRandom.hex(6)}")
    r = Rsk::Risks.new(test_pgsql, pj).add("r#{SecureRandom.hex(6)}")
    e = Rsk::Effects.new(test_pgsql, pj).add("e#{SecureRandom.hex(6)}")
    t = Rsk::Triples.new(test_pgsql, pj).add(c, r, e)
    { login: lg, pid: pj, c: c, r: r, e: e, t: t }
  end

  def test_cross_user_detach
    ip!("10.1.#{rand(200)}.#{rand(200)}")
    a = mk('aa')
    b = mk('bb')
    # B creates a plan on B's risk
    bplan = Rsk::Plans.new(test_pgsql, b[:pid]).add(b[:r], "bplan#{SecureRandom.hex(4)}")
    Rsk::Plans.new(test_pgsql, b[:pid]).get(bplan, b[:r]).reschedule('weekly')
    before = test_pgsql.exec('SELECT * FROM plan WHERE id=$1', [bplan])
    puts "PLAN #{bplan} exists before: #{!before.empty?}"
    use(a[:login], a[:pid])
    post('/responses/detach', { 'tid' => a[:t].to_s, 'id' => bplan.to_s, 'part' => b[:r].to_s })
    puts "POST /responses/detach (A session, B's plan id=#{bplan} part=#{b[:r]}) -> #{last_response.status}"
    puts "  location: #{last_response.headers['Location']}"
    puts "  flash: #{last_response.headers['Set-Cookie'].to_s[0,200]}"
    after = test_pgsql.exec('SELECT * FROM plan WHERE id=$1', [bplan])
    apart = test_pgsql.exec('SELECT * FROM part WHERE id=$1', [bplan])
    puts "PLAN #{bplan} exists after: #{!after.empty?}   part row exists after: #{!apart.empty?}"
  end

  def test_responses_add_bad_schedule
    ip!("10.2.#{rand(200)}.#{rand(200)}")
    a = mk('cc')
    use(a[:login], a[:pid])
    n0 = test_pgsql.exec('SELECT COUNT(*) FROM part WHERE project=$1 AND type=$2', [a[:pid], 'Plan'])[0]['count']
    post('/responses/add', { 'id' => a[:t].to_s, 'strategy' => a[:r].to_s, 'plan' => 'my plan', 'schedule' => 'nonsense' })
    puts "POST /responses/add schedule=nonsense -> #{last_response.status}"
    n1 = test_pgsql.exec('SELECT COUNT(*) FROM part WHERE project=$1 AND type=$2', [a[:pid], 'Plan'])[0]['count']
    puts "  plan parts before=#{n0} after=#{n1}"
    rows = test_pgsql.exec('SELECT p.id, p.part, p.schedule, pt.text FROM plan p JOIN part pt ON pt.id=p.id WHERE pt.project=$1', [a[:pid]])
    puts "  orphan plan rows: #{rows.map { |x| x.to_h }.inspect}"
  end

  def test_responses_add_missing_schedule
    ip!("10.3.#{rand(200)}.#{rand(200)}")
    a = mk('dd')
    use(a[:login], a[:pid])
    post('/responses/add', { 'id' => a[:t].to_s, 'strategy' => a[:r].to_s, 'plan' => 'my plan' })
    puts "POST /responses/add (no schedule param) -> #{last_response.status}"
    puts last_response.body.scan(/NoMethodError|undefined method[^<]*/).first(3).inspect
  end
end
