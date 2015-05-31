
module Singleton
  def instance
    if @_instance.nil?
      @_instance = self::new
    end

    @_instance
  end

end

class EntityManager < Array
  include Enumerable
  extend Singleton
  
  @@uuid = 0

  def build
    @@uuid += 1
    self << @@uuid
    yield @@uuid
  end

  private
  def initialize(*args)
    super(*args)
  end

end

class ComponentEntityID
  attr_reader :id
  def initialize(id)
    @id = id
  end
end

class ComponentManager
  include Enumerable
  extend Singleton
  
  
  def set(entity_id, obj)
    @components[entity_id] ||= {}
    @components[entity_id][obj.class] = obj
    @components[entity_id][ComponentEntityID] = ComponentEntityID.new(entity_id)
  end

  def each(&block)
    @components.each{|k, v| block.call(v)}
  end

  def delete(entity_id)
     @components.delete(entity_id)
  end
  
  def each_entity(id, &block)
    @components[id].each{|i| block.call(i)}
  end

  private
  
  def initialize
    @components = {}
    @components_ids = {}
  end

end

class Observer
  def initialize
    @notifiers = Hash.new
  end

  def add(event, &action)
    @notifiers[event] ||= Array.new
    @notifiers[event] << action
  end

  def notify(event, *args)
    @notifiers[event].each{|b| b.call(*args)} if @notifiers.key?(event)
  end
end

class SystemManager
  include Enumerable
  extend Singleton
  
  attr_accessor :userdata

  def add(&system)
    @systems << system
  end

  def run
    @systems.each{|system|
      system.call(@userdata, @observer)
    }
    if block_given?
      yield @userdata, @observer
    end
  end
  
  private
  def initialize
    @userdata = {}
    @systems = []
    @observer = Observer.new
  end

end


class ComponentBounce
end

class ComponentPosition
  attr_accessor :x, :y
  def initialize(x, y)
    @x = x; @y = y
  end
end

class ComponentRenderable
  attr_reader :renderer

  def initialize(&renderer)
    @renderer = renderer
  end
end


