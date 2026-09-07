require_relative 'test_scratch_lib'
require 'securerandom'
require 'csv'
require 'json'

class ScratchH < ScratchBase
  def test_search_shrinks_plan_list
    ip!("10.40.#{rand(250)}.#{rand(250)}")
    lg = "za#{SecureRandom.hex(6)}"
    pj = Rsk::Projects.new(test_pgsql, lg).add("p#{SecureRandom.hex(6)}")
    tag = SecureRandom.hex(4)
    c = Rsk::Causes.new(test_pgsql, pj).add("cause #{tag}")
    r = Rsk::Risks.new(test_pgsql, pj).add("risk #{tag}")
    e = Rsk::Effects.new(test_pgsql, pj).add("effect #{tag}")
    t = Rsk::Triples.new(test_pgsql, pj).add(c, r, e)
    pl = Rsk::Plans.new(test_pgsql, pj)
    pl.add(r, "alpha plan #{tag}")
    pl.add(c, "beta plan #{tag}")
    use(lg, pj)
    ['', "cause #{tag}", 'alpha plan', 'beta plan'].each do |q|
      get('/ranked', { 'q' => q })
      b = last_response.body
      puts "GET /ranked?q=#{q.inspect} -> #{last_response.status} total=#{b[/There are\s+(\d+)\s+risks/m, 1]} label=#{b[/(\d+ plans?|No plans)/, 1].inspect} P-codes=#{b.scan(/<code class='small'>P(\d+)<\/code>/).flatten.inspect}"
      get('/ranked.json', { 'q' => q })
      puts "    ranked.json plans=#{JSON.parse(last_response.body).map { |x| x['plans'] }.inspect}"
    end
  end

  def test_triple_save_partial_write
    ip!("10.41.#{rand(250)}.#{rand(250)}")
    lg = "zb#{SecureRandom.hex(6)}"
    pj = Rsk::Projects.new(test_pgsql, lg).add("p#{SecureRandom.hex(6)}")
    c = Rsk::Causes.new(test_pgsql, pj).add("orig-cause-#{SecureRandom.hex(4)}")
    r = Rsk::Risks.new(test_pgsql, pj).add("orig-risk-#{SecureRandom.hex(4)}")
    e = Rsk::Effects.new(test_pgsql, pj).add("orig-effect-#{SecureRandom.hex(4)}")
    Rsk::Triples.new(test_pgsql, pj).add(c, r, e)
    use(lg, pj)
    before = test_pgsql.exec('SELECT id,text FROM part WHERE id IN ($1,$2,$3) ORDER BY id', [c, r, e]).map { |x| x['text'] }
    prob0 = test_pgsql.exec('SELECT probability FROM risk WHERE id=$1', [r])[0]['probability']
    post('/triple/save', { 'ctext' => 'HACKED-CAUSE', 'rtext' => 'HACKED-RISK', 'etext' => 'HACKED-EFFECT',
                           'cid' => c.to_s, 'rid' => r.to_s, 'eid' => e.to_s,
                           'probability' => 'not-a-number', 'impact' => '5', 'emoji' => 'x' })
    puts "POST /triple/save probability=not-a-number -> #{last_response.status} #{last_response.headers['Set-Cookie'].to_s[/flash_msg=[^;]*/]}"
    after = test_pgsql.exec('SELECT id,text FROM part WHERE id IN ($1,$2,$3) ORDER BY id', [c, r, e]).map { |x| x['text'] }
    prob1 = test_pgsql.exec('SELECT probability FROM risk WHERE id=$1', [r])[0]['probability']
    puts "  texts before=#{before.inspect}"
    puts "  texts after =#{after.inspect}"
    puts "  risk.probability before=#{prob0} after=#{prob1}"
  end

  def test_triple_save_bad_emoji_partial_write
    ip!("10.42.#{rand(250)}.#{rand(250)}")
    lg = "zc#{SecureRandom.hex(6)}"
    pj = Rsk::Projects.new(test_pgsql, lg).add("p#{SecureRandom.hex(6)}")
    c = Rsk::Causes.new(test_pgsql, pj).add("oc-#{SecureRandom.hex(4)}")
    r = Rsk::Risks.new(test_pgsql, pj).add("orr-#{SecureRandom.hex(4)}")
    e = Rsk::Effects.new(test_pgsql, pj).add("oe-#{SecureRandom.hex(4)}")
    Rsk::Triples.new(test_pgsql, pj).add(c, r, e)
    use(lg, pj)
    post('/triple/save', { 'ctext' => 'NEW-CAUSE-TEXT', 'rtext' => 'NEW-RISK', 'etext' => 'NEW-EFFECT',
                           'cid' => c.to_s, 'rid' => r.to_s, 'eid' => e.to_s,
                           'probability' => '5', 'impact' => '5', 'emoji' => '🇺🇸' })
    puts "POST /triple/save emoji=flag -> #{last_response.status} #{last_response.headers['Set-Cookie'].to_s[/flash_msg=[^;]*/]}"
    puts "  cause text now=#{test_pgsql.exec('SELECT text FROM part WHERE id=$1', [c])[0]['text'].inspect} risk text now=#{test_pgsql.exec('SELECT text FROM part WHERE id=$1', [r])[0]['text'].inspect}"
  end
end
