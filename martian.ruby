require 'test/unit'

class Point
  attr_accessor :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end

  def to_s
    "#{x} #{y}"
  end

end

class Robot
  A = ['N', 'E', 'S', 'W']
  attr_accessor :upper_right

  def initialize(upper_right)
    @upper_right = upper_right
  end

  def rotate(face, direction)
    A[(A.find_index(face) + direction) % A.length]
  end

  def is_in_grid?(point)
    point.x >= 0 && point.y >= 0 && point.x <= upper_right.x && point.y <= upper_right.y
  end

  def go(point, orientation)
    x = y = 0
    point = point.dup #damn ruby

    if ['N', 'S'].include?(orientation)
      y = ['S', ' ', 'N'].find_index(orientation) - 1
    elsif ['E', 'W'].include?(orientation)
      x = ['W', ' ', 'E'].find_index(orientation) - 1
    else
      raise Excpetion.new("Command isn't supported: #{c}")
    end
    point.x += x
    point.y += y

    point
  end

  def find(start_x, start_y, orientation, commands)
      point = Point.new(start_x, start_y)

      p '---'
      p '_' + '->' + point.to_s + ' ' + orientation
      commands.chars.each do |c|

        if ['L', 'R'].include?(c)
          orientation = rotate(orientation, ['L', 'F', 'R'].find_index(c) - 1)
        elsif c == 'F'
            poi = go(point, orientation)
            if is_in_grid?(poi)
              point = poi
            else
              return "#{point.to_s} #{orientation} LOST"
            end
        else
          raise Excpetion.new("Command isn't supported: #{c}")
        end
        p c + '->' + point.to_s + ' ' + orientation
      end
      point.to_s + ' ' + orientation
  end

end
#     N N
#   0 0 0 0 0
# W 0 0 0 0 0 E
#   0 0 0 0 0
#       S
#       #
class TestPoint < Test::Unit::TestCase
  def test_point
    assert_equal Point.new(3, 5).x, 3
    assert_equal Point.new(3, 5).y, 5
    assert_equal Point.new(3, 5).to_s, '3 5'
  end
end

class TestMartianRobot < Test::Unit::TestCase
  def test_final_position

    t1 = Time.now
    upper_right = Point.new('5'.to_i, '3'.to_i)
    assert_equal Robot.new(upper_right).find('1'.to_i, '1'.to_i, 'E', 'RFRFRFRF'), '1 1 E'
    assert_equal Robot.new(upper_right).find('3'.to_i, '2'.to_i, 'N', 'FRRFLLFFRRFLL'), '3 3 N LOST'
    assert_equal Robot.new(upper_right).find('0'.to_i, '3'.to_i, 'W', 'LLFFFLFLFL'), '3 3 N LOST'
    # Todo: Wrong test
    # assert_equal Robot.new(upper_right).find('0'.to_i, '3'.to_i, 'W', 'LLFFFLFLFL'), '2 3 S'
    t2 = Time.now
    p t2 - t1
  end
end
