require 'polaris'
require 'sqlite3'

class SolarSystem
  attr_accessor :sid, :x, :y, :z
  def initialize(db_row)
    @sid = db_row[2]
    @x = db_row[4].to_f
    @y = db_row[5].to_f
    @z = db_row[6].to_f
  end
  
  def <=>(b)
    ret = 1
    if sid == b.sid #@x == b.x && @y == b.y && @z == b.z
      ret = 0
    end
    ret = -1 if @x <= b.x && @y < b.y && @z < b.z
    return ret
  end

  def to_s
    "#{sid} [#{x},#{y},#{z}]"
  end
end

class Map
  def initialize
    @db = SQLite3::Database.new( "dom111-sqlite3-v1.db" )
  end

  def blocked?(location,type);false;end

  def cost(from, to)
    return 0 if from.sid == to.sid
    1
  end

  def distance(from, to)
    f = from
    t = to

    dist = (t.x-f.x).abs + (t.y-f.y).abs + (t.z-f.z).abs
  end

  def neighbors(system)
    neighbors = @db.execute("select * from mapSolarSystems where solarSystemID IN (select toSolarSystemID from mapSolarSystemJumps where fromSolarSystemID=#{system.sid})")
    neighbors ||= []
    neighbors.collect{|n| SolarSystem.new(n)}
  end

  def location(id)
    SolarSystem.new(@db.execute("select * from mapSolarSystems where solarSystemID=#{id}").first)
  end

end

class EvePather
  def initialize(map)
    @map = map
  end

  def route(from, to)
    @polaris = Polaris.new @map
    @polaris.guide(from,to,nil,4_000)
  end
end

if __FILE__ == $0
  map = Map.new
  pather = EvePather.new map

  from = map.location 30000001
  to = map.location 30000003
  path = pather.route from, to
  p path

end
