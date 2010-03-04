require 'polaris'
require 'sqlite3'

class SolarSystem
  attr_accessor :sid, :x, :y, :z, :name, :sec
  def initialize(db_row)
    @sid = db_row[2]
    @name = db_row[3]
    @x = db_row[4].to_f
    @y = db_row[5].to_f
    @z = db_row[6].to_f
    @sec = db_row[21].to_f
  end
  
  def <=>(b)
    self.sid <=> b.sid
  end

  def to_s
    "#{name} (#{sid}) [#{x},#{y},#{z}] [sec: #{@sec}]"
  end
end

class Map
  attr_accessor :security_factors
  def initialize
    @db = SQLite3::Database.new( "dom111_mapData.db" )
    @neighbor_statement = @db.prepare("select * from mapSolarSystems where solarSystemID IN (select toSolarSystemID from mapSolarSystemJumps where fromSolarSystemID=?)")
    @systems = {}
    @db.execute("select * from mapSolarSystems").each do |row|
      s = SolarSystem.new(row)
      @systems[s.sid] = s
    end
    puts "loaded systems"
    @jumps = {}
    @db.execute("select * from mapSolarSystemJumps").each do |row|
      @jumps[row[2]] ||= []
      @jumps[row[2]] << row
    end
    # ignore sec by default
    @security_factors = Hash.new
    @security_factors[:highsec] = 1
    @security_factors[:lowsec] = 1
    @security_factors[:nullsec] = 1
    puts "loaded jumps"
  end

  def blocked?(location,type);false;end

  def cost(from, to)
    return 0 if from.sid == to.sid
    factor = @security_factors[:highsec] if(to.sec >= 0.5)
    factor = @security_factors[:lowsec] if(to.sec < 0.5 && to.sec > 0.0)
    factor = @security_factors[:nullsec] if(to.sec <= 0.0)
    #    return 1 + (1-to.sec)*factor
    return factor
  end

  def distance(from, to)
    @scale ||= 1/"5e+33".to_f
    f = from
    t = to

    x_dist = t.x-f.x
    y_dist = t.y-f.y
    z_dist = t.z-f.z
    dist = x_dist * x_dist + y_dist * y_dist + z_dist * z_dist
    dist * @scale
  end

  def neighbors(system)
    neighbors = @jumps[system.sid].collect{|n| @systems[n[3]]}
    neighbors ||= []
  end

  def location(id)
    @systems[id.to_s]
  end

end

class EvePather
  def initialize(map)
    @map = map
  end

  def route(from, to)
    @polaris = Polaris.new @map
    @polaris.guide(from,to,nil,400_000)
  end
end

if __FILE__ == $0
  map = Map.new
  #  UNCOMMENT TO TAKE SECURITY INTO ACCOUNT
  map.security_factors[:highsec] = 1
  map.security_factors[:lowsec] = 1
  map.security_factors[:nullsec] = 1
  pather = EvePather.new map

#  D7-ZAC
  from = map.location 30000867
#  Aldrat
  to = map.location 30003416

  path = nil
  require 'benchmark'
  Benchmark.bm(10) do |x|
    x.report("D7-ZAC to Aldrat 10") do
      10.times do
        path = pather.route from, to
      end
    end
  end


#  path = pather.route from, to
  path ||= []
  p path.collect{|system|system.location.name}
  p path.size

end
