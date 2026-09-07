require_relative 'test_scratch_lib'
require 'securerandom'
require 'csv'

class ScratchJ < ScratchBase
  def test_delete_project_with_data
    ip!("10.60.#{rand(250)}.#{rand(250)}")
    lg = "pa#{SecureRandom.hex(6)}"
    pj = Rsk::Projects.new(test_pgsql, lg).add("p#{SecureRandom.hex(6)}")
    use(lg, pj)
    # 1. project with a single cause only
    Rsk::Causes.new(test_pgsql, pj).add("c#{SecureRandom.hex(6)}")
    post('/projects/delete', { 'id' => pj.to_s })
    puts "POST /projects/delete (project with 1 cause) -> #{last_response.status}"
    puts "  err: #{last_response.body[/ERROR:[^<\\\n]*/]}"
    puts "  project still exists: #{!test_pgsql.exec('SELECT * FROM project WHERE id=$1', [pj]).empty?}"
    # 2. totally empty project
    pj2 = Rsk::Projects.new(test_pgsql, lg).add("q#{SecureRandom.hex(6)}")
    post('/projects/delete', { 'id' => pj2.to_s })
    puts "POST /projects/delete (empty project) -> #{last_response.status} exists=#{!test_pgsql.exec('SELECT * FROM project WHERE id=$1', [pj2]).empty?}"
  end

  def test_csv_vs_html_consistency
    ip!("10.61.#{rand(250)}.#{rand(250)}")
    lg = "pb#{SecureRandom.hex(6)}"
    pj = Rsk::Projects.new(test_pgsql, lg).add("p#{SecureRandom.hex(6)}")
    cs = Rsk::Causes.new(test_pgsql, pj)
    30.times { |i| cs.add(format('cc-%<i>02d-%<h>s', i: i, h: SecureRandom.hex(4))) }
    use(lg, pj)
    get('/causes.csv')
    csv = CSV.parse(last_response.body)[1..].map { |r| r[0] }
    get('/causes?limit=25&offset=0')
    html1 = last_response.body.scan(/<code>C(\d+)<\/code>/).flatten
    get('/causes?limit=25&offset=25')
    html2 = last_response.body.scan(/<code>C(\d+)<\/code>/).flatten
    puts "csv rows=#{csv.size}  html p1=#{html1.size} p2=#{html2.size} union=#{(html1 + html2).uniq.size}"
    puts "csv == html order? #{csv == (html1 + html2)}"
    puts "csv set == html set? #{csv.sort == (html1 + html2).sort}"
  end

  def test_detach_wrong_part_false_success
    ip!("10.62.#{rand(250)}.#{rand(250)}")
    lg = "pc#{SecureRandom.hex(6)}"
    pj = Rsk::Projects.new(test_pgsql, lg).add("p#{SecureRandom.hex(6)}")
    c = Rsk::Causes.new(test_pgsql, pj).add("c#{SecureRandom.hex(6)}")
    r = Rsk::Risks.new(test_pgsql, pj).add("r#{SecureRandom.hex(6)}")
    e = Rsk::Effects.new(test_pgsql, pj).add("e#{SecureRandom.hex(6)}")
    t = Rsk::Triples.new(test_pgsql, pj).add(c, r, e)
    pl = Rsk::Plans.new(test_pgsql, pj)
    p1 = pl.add(r, "pp#{SecureRandom.hex(4)}")
    use(lg, pj)
    post('/responses/detach', { 'tid' => t.to_s, 'id' => p1.to_s, 'part' => c.to_s })
    puts "POST /responses/detach with wrong part -> #{last_response.status} #{last_response.headers['Set-Cookie'].to_s[/flash_msg=[^;]*/]}"
    puts "  plan still attached: #{!test_pgsql.exec('SELECT * FROM plan WHERE id=$1', [p1]).empty?}"
  end

  def test_plans_page_and_totals
    ip!("10.63.#{rand(250)}.#{rand(250)}")
    lg = "pd#{SecureRandom.hex(6)}"
    pj = Rsk::Projects.new(test_pgsql, lg).add("p#{SecureRandom.hex(6)}")
    c = Rsk::Causes.new(test_pgsql, pj).add("c#{SecureRandom.hex(6)}")
    r = Rsk::Risks.new(test_pgsql, pj).add("r#{SecureRandom.hex(6)}")
    e = Rsk::Effects.new(test_pgsql, pj).add("e#{SecureRandom.hex(6)}")
    e2 = Rsk::Effects.new(test_pgsql, pj).add("e2#{SecureRandom.hex(6)}")
    Rsk::Triples.new(test_pgsql, pj).add(c, r, e)
    Rsk::Triples.new(test_pgsql, pj).add(c, r, e2)
    pl = Rsk::Plans.new(test_pgsql, pj)
    pl.add(r, "plan-x-#{SecureRandom.hex(4)}")
    puts "plans.count=#{pl.count} fetch=#{pl.fetch(limit: 20).map { |x| [x[:id], x[:triple], x[:rank]] }.inspect}"
    use(lg, pj)
    get('/plans')
    puts "GET /plans -> #{last_response.status} #{last_response.body[/undefined method[^<\\\n]*/]}"
  end
end
