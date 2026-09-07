require_relative 'test_scratch_lib'
require 'securerandom'

class ScratchG < ScratchBase
  def test_select_other_users_project
    ip!("10.30.#{rand(250)}.#{rand(250)}")
    alg = "ya#{SecureRandom.hex(6)}"
    apj = Rsk::Projects.new(test_pgsql, alg).add("pa#{SecureRandom.hex(6)}")
    blg = "yb#{SecureRandom.hex(6)}"
    bpj = Rsk::Projects.new(test_pgsql, blg).add("pb#{SecureRandom.hex(6)}")
    secret = "SECRET-#{SecureRandom.hex(6)}"
    bc = Rsk::Causes.new(test_pgsql, bpj).add(secret)
    br = Rsk::Risks.new(test_pgsql, bpj).add("br#{SecureRandom.hex(6)}")
    be = Rsk::Effects.new(test_pgsql, bpj).add("be#{SecureRandom.hex(6)}")
    Rsk::Triples.new(test_pgsql, bpj).add(bc, br, be)
    puts "A login=#{alg} pid=#{apj}; B login=#{blg} pid=#{bpj} secret cause=#{secret}"

    use(alg, apj)
    post('/projects/select', { 'id' => bpj.to_s })
    puts "POST /projects/select id=#{bpj} -> #{last_response.status} setcookie=#{last_response.headers['Set-Cookie'].inspect}"
    puts "jar: #{last_request.env["HTTP_COOKIE"].inspect}"
    get('/causes')
    puts "GET /causes -> #{last_response.status}"
    puts "  leaks B's secret cause? #{last_response.body.include?(secret)}"
    puts "  page total: #{last_response.body[/There are\s+(\d+)\s+causes/m, 1].inspect}"
    get('/causes.csv')
    puts "GET /causes.csv -> #{last_response.status} body=#{last_response.body.inspect}"
    get('/ranked')
    puts "GET /ranked -> #{last_response.status} leaks=#{last_response.body.include?(secret)}"

    # Also: raw cookie, no /projects/select at all
    ip!("10.31.#{rand(250)}.#{rand(250)}")
    clear_cookies
    set_cookie("glogin=#{alg}")
    set_cookie("0rsk-project=#{bpj}")
    get('/causes')
    puts "raw cookie 0rsk-project=#{bpj} as A: GET /causes -> #{last_response.status} leaks=#{last_response.body.include?(secret)}"
  end
end
