require_relative 'test_scratch_lib'
require 'securerandom'

class ScratchD < ScratchBase
  def test_bad_limit_and_offset
    ip!("10.7.#{rand(200)}.#{rand(200)}")
    lg = "hh#{SecureRandom.hex(6)}"
    pj = Rsk::Projects.new(test_pgsql, lg).add("p#{SecureRandom.hex(6)}")
    Rsk::Causes.new(test_pgsql, pj).add("c#{SecureRandom.hex(6)}")
    use(lg, pj)
    [['/causes', 'limit=-1'], ['/ranked', 'limit=-5'], ['/causes', 'limit=0'],
     ['/causes', 'offset=-3'], ['/ranked', 'limit=abc'], ['/plans', 'limit=-2'],
     ['/tasks', 'limit=-2'], ['/effects', 'limit=-2'], ['/risks', 'limit=-2'],
     ['/causes', 'limit=99999999999999999999']].each do |path, qs|
      get("#{path}?#{qs}")
      err = last_response.body[/ERROR:[^<\\\n]*/] || last_response.body[/[A-Za-z:]*Error[^<\\\n]{0,80}/]
      puts "GET #{path}?#{qs} -> #{last_response.status}  #{err}"
    end
  end

  def test_search_backslash_detail
    ip!("10.8.#{rand(200)}.#{rand(200)}")
    lg = "ii#{SecureRandom.hex(6)}"
    pj = Rsk::Projects.new(test_pgsql, lg).add("p#{SecureRandom.hex(6)}")
    cs = Rsk::Causes.new(test_pgsql, pj)
    cs.add('c:\\windows\\path')
    cs.add('one hundred % done')
    cs.add('snake_case name')
    { 'backslash' => '\\', 'winpath' => 'c:\\windows', 'pct' => '%', 'us' => '_' }.each do |n, q|
      cnt = cs.count(query: q)
      rows = cs.fetch(query: q, limit: 50).map { |r| r[:text] }
      puts "causes.count(q=#{q.inspect}) [#{n}] = #{cnt}  rows=#{rows.inspect}"
    end
    puts "all rows: #{cs.fetch(limit: 50).map { |r| r[:text] }.inspect}"
  end

  def test_paging_next_link
    ip!("10.9.#{rand(200)}.#{rand(200)}")
    lg = "jj#{SecureRandom.hex(6)}"
    pj = Rsk::Projects.new(test_pgsql, lg).add("p#{SecureRandom.hex(6)}")
    cs = Rsk::Causes.new(test_pgsql, pj)
    30.times { |i| cs.add(format('cause-%<i>02d-%<h>s', i: i, h: SecureRandom.hex(4))) }
    use(lg, pj)
    seen = Hash.new(0)
    (0..3).each do |p|
      off = p * 10
      get("/causes?limit=10&offset=#{off}")
      body = last_response.body
      ids = body.scan(/<code>C(\d+)<\/code>/).flatten
      total = body[/There are\s+(\d+)\s+causes/m, 1]
      nxt = body.include?('title=\'Next page\'') || body.include?('title="Next page"')
      puts "GET /causes?limit=10&offset=#{off} -> #{last_response.status} total=#{total} items=#{ids.size} nextlink=#{nxt}"
      ids.each { |i| seen[i] += 1 }
    end
    puts "distinct ids seen=#{seen.size}  duplicated=#{seen.select { |_, v| v > 1 }.size}  expected 30"
    # exactly-full last page
    get('/causes?limit=15&offset=15')
    puts "GET /causes?limit=15&offset=15 -> items=#{last_response.body.scan(/<code>C(\d+)<\/code>/).size} nextlink=#{last_response.body.include?('Next page')}"
    get('/causes?limit=15&offset=30')
    puts "GET /causes?limit=15&offset=30 -> status=#{last_response.status} body_has_nothing_found=#{last_response.body.include?('Nothing')} items=#{last_response.body.scan(/<code>C(\d+)<\/code>/).size}"
  end
end
