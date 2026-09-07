require_relative 'test_scratch_lib'
require 'securerandom'

class ScratchA < ScratchBase
  def test_smoke
    ip!('10.0.0.1')
    lg = "u#{SecureRandom.hex(6)}"
    pj = Rsk::Projects.new(test_pgsql, lg).add("p#{SecureRandom.hex(6)}")
    c = Rsk::Causes.new(test_pgsql, pj).add("c#{SecureRandom.hex(6)}")
    r = Rsk::Risks.new(test_pgsql, pj).add("r#{SecureRandom.hex(6)}")
    e = Rsk::Effects.new(test_pgsql, pj).add("e#{SecureRandom.hex(6)}")
    t = Rsk::Triples.new(test_pgsql, pj).add(c, r, e)
    use(lg, pj)
    get('/ranked')
    puts "GET /ranked -> #{last_response.status}"
    puts last_response.body[0, 400] unless last_response.ok?
    get("/responses?id=#{t}")
    puts "GET /responses?id=#{t} -> #{last_response.status}"
    puts "login=#{lg} pid=#{pj} c=#{c} r=#{r} e=#{e} t=#{t}"
  end
end
