
#can't walk throught
class ComponentSolid; end

#Class ComponentFrameSheet
#properties for rendering a frame from sheet
class ComponentFrameSheet
  attr_reader :x, :y
  def initialize(x, y)
    @x = x; @y = y
  end
end

class ComponentSystemEvent
  attr_accessor :events
  def initialize
    @events = []
  end
end

class ComponentSharedData
  def initialize(data)
    @data = data
  end

  def [](key)
    @data[key]
  end

  def []=(key, val)
    @data[key] = val
  end
end

class ComponentPlayer
  attr_reader :up, :down, :left, :right, :bomb
  
  attr_accessor :bomb_strong

  
  def initialize(up, down, left, right, bomb)
    @up = up; @down = down; @left = left; @right = right; @bomb = bomb
    @bomb_strong = 10
  end
end

class ComponentTickout
  #::tickout:: time before explode
  def initialize(tickout, &cb)
    @tickout = tickout
    @callback = cb if block_given?
  end

  def tick
    @tickout -= 1
  end

  def out(entity)
    @callback.call(entity) unless @callback.nil?
  end
  
  def out?
    @tickout <= 0
  end
end

class ComponentBomb < ComponentTickout
  attr_reader :strong
  def initialize(tickout, strong, &cb)
    super(tickout, &cb)
    @strong = strong
  end
end

class ComponentBrick
end

class ComponentHurt < ComponentTickout
end

class ComponentAvatar
  attr_reader :frames

  def initialize(frames)
    @frames = frames
  end
end

class ComponentStep
  attr_reader :steps
  def initialize(steps)
    @steps = steps
  end

  def dec
    @steps -= 1
  end
end

class ComponentDirection
  attr_reader :direction

  def initialize(direction)
    @direction = direction
  end

  def left?
    @direction == :left
  end
  def left!
    @direction = :left
  end

  def right?
    @direction == :right
  end
  def right!
    @direction = :right
  end
  
  def up?
    @direction == :up
  end
  def up!
    @direction = :up
  end

  def down?
    @direction == :down
  end
  def down!
    @direction = :down
  end

  def clean!
    @direction = nil
  end
end
