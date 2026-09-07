require_relative 'test_scratch_lib'
require 'securerandom'
require 'csv'

class ScratchC < ScratchBase
  def test_search_edge_chars
    ip!("10.4.#{rand(200)}.#{rand(200)}")
    lg = "ee#{SecureRandom.hex(6)}"
    pj = Rsk::Projects.new(test_pgsql, lg).add("p#{SecureRandom.hex(6)}")
    Rsk::Causes.new(test_pgsql, pj).add('one hundred % done')
    Rsk::Causes.new(test_pgsql, pj).add('snake_case name')
    Rsk::Causes.new(test_pgsql, pj).add('back\\slash here')
    Rsk::Causes.new(test_pgsql, pj).add("quote ' and \" here")
    Rsk::Causes.new(test_pgsql, pj).add('многобайтовый текст')
    use(lg, pj)
    {
      'percent' => '%', 'underscore' => '_', 'backslash' => '\\',
      'quote' => "'", 'dquote' => '"', 'multibyte' => 'текст',
      'trailing-bs' => 'abc\\', 'pct-word' => '% done'
    }.each do |name, q|
      get('/causes', { 'q' => q })
      body = last_response.body
      n = body.scan(/There are\s+(\d+)\s+causes/m).flatten.first
      puts "GET /causes?q=#{q.inspect} (#{name}) -> #{last_response.status} total=#{n.inspect}"
      puts "   ERR: #{body.scan(/PG::[A-Za-z]+[^<\\]*/).first}" unless last_response.ok?
    end
  end

  def test_bad_limit_and_offset
    ip!("10.5.#{rand(200)}.#{rand(200)}")
    lg = "ff#{SecureRandom.hex(6)}"
    pj = Rsk::Projects.new(test_pgsql, lg).add("p#{SecureRandom.hex(6)}")
    Rsk::Causes.new(test_pgsql, pj).add("c#{SecureRandom.hex(6)}")
    use(lg, pj)
    [['/causes', 'limit', '-1'], ['/ranked', 'limit', '-5'], ['/causes', 'limit', '0'],
     ['/causes', 'offset', '-3'], ['/ranked', 'limit', 'abc'], ['/causes', 'limit', '99999999999999999999']].each do |path, k, v|
      get(path, { k => v })
      puts "GET #{path}?#{k}=#{v} -> #{last_response.status}  #{last_response.body.scan(/PG::[A-Za-z]+[^<\\]*|ArgumentError[^<\\]*/).first}"
    end
  end

  def test_ranked_plus_query
    ip!("10.6.#{rand(200)}.#{rand(200)}")
    lg = "gg#{SecureRandom.hex(6)}"
    pj = Rsk::Projects.new(test_pgsql, lg).add("p#{SecureRandom.hex(6)}")
    use(lg, pj)
    ['+99999999999999999999', '+alone', '+0', '+bogus', '+'].each do |q|
      get('/ranked', { 'q' => q })
      puts "GET /ranked?q=#{q} -> #{last_response.status}  #{last_response.body.scan(/PG::[A-Za-z]+[^<\\]*/).first}"
    end
  end
end
