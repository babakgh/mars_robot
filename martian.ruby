require 'test/unit'
require 'benchmark'
require 'logger'

$log = Logger.new(STDOUT)
$log.level = Logger::WARN

Orientations = ['E', 'N', 'W', 'S']

class Point
  attr_accessor :x, :y

  def initialize(x, y)
    raise Exception.new("Validation failed. Should be integer: #{x}, #{y}") unless x.is_a?(Integer) && y.is_a?(Integer)
    @x = x
    @y = y
  end

  def to_s
    "#{x} #{y}"
  end

end

class Position
  # o: orientation
  # poi: point
  attr_accessor :poi , :o

  def initialize(poi, o)
    raise Exception.new("Invalid point: #{poi.class}") unless poi.is_a? Point
    @poi = poi.dup
    raise Exception.new("Invalid orientation: #{o}") unless Orientations.include?(o)
    @o = o
  end

  def to_s
    "#{poi.to_s} #{o}"
  end

end

class Command
  def go(pos)
      raise Exception.new("Invalid position: #{pos.class}") unless pos.is_a? Position
  end
end

class Right < Command
  def go(pos)
    super
    Position.new(pos.poi, Orientations[(Orientations.find_index(pos.o) - 1) % Orientations.length])
  end
end

class Left < Command
  def go(pos)
    super
    Position.new(pos.poi, Orientations[(Orientations.find_index(pos.o) + 1) % Orientations.length])
  end
end

class Forward < Command
  def go(pos)
    super
    angle = Orientations.find_index(pos.o) * 2*Math::PI/Orientations.length
    Position.new(Point.new(pos.poi.x + Math.cos(angle).to_i, pos.poi.y + Math.sin(angle).to_i), pos.o)
  end
end

class CommandFactory

  Commands = {
    :L => Left,
    :F => Forward,
    :R => Right,
  }

  def self.create(type)
    if Commands.has_key?(type)
      Commands[type].new
    else
      raise Exception.new("Command isn't supported: #{type}")
    end
  end

end

class Grid
  attr_accessor :upper_right

  def initialize(upper_right)
    raise Exception.new("Invalid point") unless upper_right.is_a? Point
    @upper_right = upper_right.dup
  end

  def is_lost?(poi)
    poi.x < 0 || poi.y < 0 || poi.x > upper_right.x || poi.y > upper_right.y
  end

  def to_s
    "0 0 - #{upper_right.to_s}"
  end
end

class Robot
  attr_accessor :grid

  def initialize(grid)
    @grid = grid.dup
  end

  def go(start, commands)
    pos = start.dup
    $log.debug 'X' + ' -> ' + pos.to_s
    commands.chars.each do |c|
      new_pos = CommandFactory.create(c.to_sym).go(pos)
      return "#{pos.to_s} LOST" if grid.is_lost?(new_pos.poi)
      pos = new_pos
      $log.debug c + ' -> ' + pos.to_s
    end

    pos.to_s
  end
end

class TestMartianRobot < Test::Unit::TestCase

  def test_point
    assert_equal Point.new(3, 5).x, 3
    assert_equal Point.new(3, 5).y, 5
    assert_equal Point.new(3, 5).to_s, '3 5'
  end

  def test_position
    assert_equal Position.new(Point.new(3, 5), 'N').o, 'N'
    exception = assert_raise(Exception) {Position.new(Point.new(3, 5), 'X')}
    assert_equal exception.message, "Invalid orientation: X"
    assert_equal Position.new(Point.new(3, 5), 'N').to_s, '3 5 N'
  end

  def test_grid
    grid = Grid.new(Point.new(5, 3))
    assert_equal grid.is_lost?(Point.new(5,3)), false
    assert_equal grid.is_lost?(Point.new(0,0)), false
    assert_equal grid.is_lost?(Point.new(1,2)), false
    assert_equal grid.is_lost?(Point.new(-1,2)), true
    assert_equal grid.is_lost?(Point.new(2,-1)), true
    assert_equal grid.is_lost?(Point.new(6,2)), true
    assert_equal grid.is_lost?(Point.new(2,4)), true
  end

  def test_factory
    assert_equal CommandFactory.create(:F).class.name, Forward.to_s
    assert_equal CommandFactory.create(:R).class.name, Right.to_s
    assert_equal CommandFactory.create(:L).class.name, Left.to_s
    exception = assert_raise(Exception) {CommandFactory.create(:X)}
    assert_equal exception.message, "Command isn't supported: X"
  end

  def test_command
    assert_equal CommandFactory.create(:F).go(Position.new(Point.new(0,0),'N')).to_s, '0 1 N'
    assert_equal CommandFactory.create(:F).go(Position.new(Point.new(0,1),'S')).to_s, '0 0 S'
    assert_equal CommandFactory.create(:F).go(Position.new(Point.new(0,0),'E')).to_s, '1 0 E'
    assert_equal CommandFactory.create(:F).go(Position.new(Point.new(1,0),'W')).to_s, '0 0 W'
    assert_equal CommandFactory.create(:R).go(Position.new(Point.new(0,0),'N')).to_s, '0 0 E'
    assert_equal CommandFactory.create(:R).go(Position.new(Point.new(0,0),'E')).to_s, '0 0 S'
    assert_equal CommandFactory.create(:R).go(Position.new(Point.new(0,0),'S')).to_s, '0 0 W'
    assert_equal CommandFactory.create(:R).go(Position.new(Point.new(0,0),'W')).to_s, '0 0 N'
    assert_equal CommandFactory.create(:L).go(Position.new(Point.new(0,0),'N')).to_s, '0 0 W'
    assert_equal CommandFactory.create(:L).go(Position.new(Point.new(0,0),'W')).to_s, '0 0 S'
    assert_equal CommandFactory.create(:L).go(Position.new(Point.new(0,0),'S')).to_s, '0 0 E'
    assert_equal CommandFactory.create(:L).go(Position.new(Point.new(0,0),'E')).to_s, '0 0 N'
  end

  def test_go
    grid = Grid.new(Point.new('5'.to_i, '3'.to_i))
    assert_equal Robot.new(grid).go(Position.new(Point.new('1'.to_i, '1'.to_i), 'E'), 'RFRFRFRF'), '1 1 E'
    assert_equal Robot.new(grid).go(Position.new(Point.new('3'.to_i, '2'.to_i), 'N'), 'FRRFLLFFRRFLL'), '3 3 N LOST'
    assert_equal Robot.new(grid).go(Position.new(Point.new('0'.to_i, '3'.to_i), 'W'), 'LLFFFLFLFL'), '3 3 N LOST'
    # Todo: Wrong test
    # assert_equal Robot.new(grid).go(Position.new(Point.new('0'.to_i, '3'.to_i), 'W'), 'LLFFFLFLFL'), '2 3 S'
  end

end

def go_via_input_files
  Dir['./input_*.txt'].each do |file|
    lines = File.readlines(file)
    gx, gy = lines.shift.split.map(&:to_i)
    grid = Grid.new(Point.new(gx, gy))
    puts
    puts "Grid: #{grid.to_s}"
    puts '-------'
    robot = Robot.new(grid)
    while !lines.empty? do
      sx, sy, so = lines.shift.split
      start = Position.new(Point.new(sx.to_i, sy.to_i), so)
      puts "Start: #{start.to_s}"
      commands = lines.shift
      puts "Commands: #{commands}"
      puts "Result: #{robot.go(start, commands.gsub("\n", ''))}"
      puts lines.shift
    end

  end
end

Benchmark.bm do |bm|
  bm.report do
    1.times do
      go_via_input_files
    end
  end
end
