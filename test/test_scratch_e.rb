require_relative 'test_scratch_lib'
require 'securerandom'
require 'csv'

class ScratchE < ScratchBase
  def test_empty_page_message
    ip!("10.11.#{rand(200)}.#{rand(200)}")
    lg = "kk#{SecureRandom.hex(6)}"
    pj = Rsk::Projects.new(test_pgsql, lg).add("p#{SecureRandom.hex(6)}")
    cs = Rsk::Causes.new(test_pgsql, pj)
    30.times { |i| cs.add(format('cz-%<i>02d-%<h>s', i: i, h: SecureRandom.hex(4))) }
    use(lg, pj)
    get('/causes?limit=15&offset=30')
    b = last_response.body
    puts "GET /causes?limit=15&offset=30 -> #{last_response.status}"
    puts "  contains 'No causes as of yet.' : #{b.include?('No causes as of yet.')}"
    puts "  contains any paging link       : #{b.include?('Previous')} / next=#{b.include?('Next')}"
  end

  def test_ranked_count_with_two_plans
    ip!("10.12.#{rand(200)}.#{rand(200)}")
    lg = "ll#{SecureRandom.hex(6)}"
    pj = Rsk::Projects.new(test_pgsql, lg).add("p#{SecureRandom.hex(6)}")
    c = Rsk::Causes.new(test_pgsql, pj).add("c#{SecureRandom.hex(6)}")
    r = Rsk::Risks.new(test_pgsql, pj).add("r#{SecureRandom.hex(6)}")
    e = Rsk::Effects.new(test_pgsql, pj).add("e#{SecureRandom.hex(6)}")
    t = Rsk::Triples.new(test_pgsql, pj).add(c, r, e)
    pl = Rsk::Plans.new(test_pgsql, pj)
    p1 = pl.add(r, "plan-one-#{SecureRandom.hex(4)}")
    p2 = pl.add(c, "plan-two-#{SecureRandom.hex(4)}")
    tr = Rsk::Triples.new(test_pgsql, pj)
    puts "triples.count=#{tr.count} fetch.size=#{tr.fetch(limit: 50).size} plans=#{tr.fetch(limit: 50).map { |x| x[:plans] }.inspect}"
    use(lg, pj)
    get('/ranked')
    b = last_response.body
    puts "GET /ranked total=#{b[/There are\s+(\d+)\s+risks/m, 1]} rows=#{b.scan(/Edit triple/).size} plans_label=#{b[/(\d+ plans?)/, 1]}"
    get('/ranked.csv')
    puts "GET /ranked.csv -> #{last_response.status} ct=#{last_response.content_type}"
    rows = CSV.parse(last_response.body)
    puts "  csv: #{rows.inspect}"
    get('/ranked.json')
    puts "GET /ranked.json -> #{last_response.body}"
  end

  def test_csv_special_text
    ip!("10.13.#{rand(200)}.#{rand(200)}")
    lg = "mm#{SecureRandom.hex(6)}"
    pj = Rsk::Projects.new(test_pgsql, lg).add("p#{SecureRandom.hex(6)}")
    cs = Rsk::Causes.new(test_pgsql, pj)
    cs.add("comma, inside #{SecureRandom.hex(3)}")
    cs.add("quote \" inside #{SecureRandom.hex(3)}")
    cs.add("-minus start #{SecureRandom.hex(3)}")
    cs.add("=formula #{SecureRandom.hex(3)}")
    cs.add("new\nline #{SecureRandom.hex(3)}")
    use(lg, pj)
    get('/causes.csv')
    puts "GET /causes.csv -> #{last_response.status} ct=#{last_response.content_type}"
    puts last_response.body
    get('/causes')
    texts = last_response.body.scan(%r{<td>\s*\n?\s*([^<>\n][^<]*)\n\s*</td>}).flatten
    puts "HTML texts: #{texts.map(&:strip).reject(&:empty?).inspect}"
  end

  def test_csv_zero_rows
    ip!("10.14.#{rand(200)}.#{rand(200)}")
    lg = "nn#{SecureRandom.hex(6)}"
    pj = Rsk::Projects.new(test_pgsql, lg).add("p#{SecureRandom.hex(6)}")
    use(lg, pj)
    %w[/causes.csv /risks.csv /effects.csv /ranked.csv /ranked.json].each do |p|
      get(p)
      puts "GET #{p} (empty project) -> #{last_response.status} body=#{last_response.body[0, 120].inspect}"
    end
  end
end
