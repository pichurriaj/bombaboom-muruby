#Script start
if $: #need for running on PC
     $: << '.'
end

load "engine.rb"
load "components.rb"
load "maps.rb"

class AnimateFrame

  def initialize(seq, options = {})
    @seq = seq
    @options = options
  end

  def render(sheet, renderer, pos)
    sheet.blit(@seq[0].at(0), @seq[0].at(1), renderer, pos)
  end
end

class BasicSheet
  def initialize(renderer, file, width, height, cell)
    @size_cell = cell
    @width = width; @height = height
    @sheet = SDL2::Video::Surface.load_bmp(file)

    @sheet.rle true

    @sheet.color_key_set(1, @sheet.format.mapRGB(0xff, 0x00, 0xff))

    @texture = SDL2::Video::Texture.new(renderer, @sheet)
    @static = {}
  end

  def set(id, idx, idy)
    @static[id] = [idx, idy]
  end

  def blit_static(id, renderer, pos)
    blit(@static[id].at(0), @static[id].at(1), renderer, pos)
  end
  
  def blit(idx, idy, renderer, pos)
    frame = SDL2::Rect.new(@size_cell * idx, @size_cell * idy, @size_cell, @size_cell)
    renderer.copy(@texture, frame, SDL2::Rect.new(pos.x * @size_cell, pos.y * @size_cell, @size_cell, @size_cell))
  end
end

class BasicMap
  
  #::sheet:: the sprite sheet
  #::map:: [[sheetx, sheety, mapx, mapy]...]
  def initialize(sheet, map, objects)
    @sheet = sheet
    @map = map
    @objects = objects
  end

  def blit(renderer)
    @map.each { |cell|
      @sheet.blit(cell.at(0), cell.at(1), renderer, SDL2::Point.new(cell.at(2), cell.at(3)))
    }
  end

  def build(entity_manager, component_manager, sheet)
    @objects.each{ |cell|
      entity_manager.build {|eid|
        case cell.at(4)
        when :brick
          component_manager.set(eid, ComponentBrick.new)
          component_manager.set(eid, ComponentFrameSheet.new(cell.at(0), cell.at(1)))
        else
          component_manager.set(eid, ComponentFrameSheet.new(cell.at(0), cell.at(1)))
        end
        component_manager.set(eid, ComponentSolid.new)
        component_manager.set(eid, ComponentPosition.new(cell.at(2), cell.at(3)))

      }
    }

  end
end

### SYSTEM MANAGER
SystemManager.instance.userdata[:screen] = {
  :width => 256, :height => 256,
  :cols => 15, :rows => 15
}
SystemManager.instance.userdata[:player] = {
  life: 4
}

SystemManager.instance.observer.add(:collision) {|entity, with|
  if entity[ComponentHurt] and with[ComponentSolid]
    EntityManager.instance.delete(entity[ComponentEntityID].id)
    ComponentManager.instance.delete(entity[ComponentEntityID].id)
  end
  
  #destroy something brickable when receive damage
  if entity[ComponentHurt] and with[ComponentBrick]
    EntityManager.instance.delete(with[ComponentEntityID].id)
    ComponentManager.instance.delete(with[ComponentEntityID].id)
  end

  #ups the fire destroy the item
  if entity[ComponentHurt] and with[ComponentDrag]
    EntityManager.instance.delete(with[ComponentEntityID].id)
    ComponentManager.instance.delete(with[ComponentEntityID].id)
  end

  #the entity take a item
  if entity[ComponentAvatar] and with[ComponentDrag]
    EntityManager.instance.delete(with[ComponentEntityID].id)
    ComponentManager.instance.delete(with[ComponentEntityID].id)
  end

  if entity[ComponentHurt] and with[ComponentPlayer]
    puts "upss that's hurt"
  end

  if entity[ComponentPlayer]
    puts "upss tha't to hard"
  end
}

SystemManager.instance.add{|userdata, observer|
  
  ComponentManager.instance.select{|entity| entity[ComponentBomb] || entity[ComponentHurt] || entity[ComponentTickout]}.each{|entity|
    tickout = entity[ComponentBomb] || entity[ComponentHurt] || entity[ComponentTickout]
    tickout.tick
    if tickout.out?
      tickout.out(entity)
      EntityManager.instance.delete(entity[ComponentEntityID].id)
      ComponentManager.instance.delete(entity[ComponentEntityID].id)
    end
  }
 
}

#System for player manager
SystemManager.instance.add{|userdata, observer|
  ComponentManager.instance.select{|entity| entity[ComponentSystemEvent] and entity[ComponentPlayer] and entity[ComponentPosition] and entity[ComponentDirection]}.each{|entity|
    entity[ComponentDirection].clean!
    until (ev = entity[ComponentSystemEvent].events.pop).nil?
      case ev.type
      when SDL2::Input::SDL_KEYDOWN
        case ev.keysym.scancode
        when entity[ComponentPlayer].up
          entity[ComponentDirection].up!
        when entity[ComponentPlayer].down
          entity[ComponentDirection].down!
        when entity[ComponentPlayer].left
          entity[ComponentDirection].left!
        when entity[ComponentPlayer].right
          entity[ComponentDirection].right!
        when entity[ComponentPlayer].bomb
          EntityManager.instance.build{|eid|
            bomb = ComponentBomb.new(100, entity[ComponentPlayer].bomb_strong) {|bentity|
              %w(right left up down).each {|dir|
                EntityManager.instance.build{|hid|
                  ComponentManager.instance.set(hid, ComponentHurt.new(1 * bentity[ComponentBomb].strong))
                  ComponentManager.instance.set(hid, ComponentFrameSheet.new(15, 4))
                  ComponentManager.instance.set(hid, ComponentSharedData.new(:counter => 0, :strong => bentity[ComponentBomb].strong))
                  ComponentManager.instance.set(hid, ComponentSolid.new)
                  ComponentManager.instance.set(hid, ComponentDirection.new(dir.to_sym))
                  ComponentManager.instance.set(hid, ComponentStep.new(bentity[ComponentBomb].strong))
                  ComponentManager.instance.set(hid, ComponentPosition.new(bentity[ComponentPosition].x, bentity[ComponentPosition].y))

                }
              }
            }
            ComponentManager.instance.set(eid, bomb)
            ComponentManager.instance.set(eid, ComponentSolid.new)
            ComponentManager.instance.set(eid, ComponentFrameSheet.new(14, 3))
            ComponentManager.instance.set(eid, ComponentPosition.new(entity[ComponentPosition].x, entity[ComponentPosition].y))
          }
        end
      end
    end
  }

  #collision
  ComponentManager.instance.select{|entity| entity[ComponentDirection] and entity[ComponentPosition]}.each{|entity|

    ComponentManager.instance.select{|e| e[ComponentSolid] and e[ComponentPosition] and e != entity}.each{|block|
      case entity[ComponentDirection].direction
      when :right
        if block[ComponentPosition].y == entity[ComponentPosition].y and block[ComponentPosition].x == entity[ComponentPosition].x + 1
          observer.notify(:collision, entity, block)
          entity[ComponentDirection].clean!
          break
        end
      when :left
        if block[ComponentPosition].y == entity[ComponentPosition].y and block[ComponentPosition].x == entity[ComponentPosition].x - 1
          observer.notify(:collision, entity, block)
          entity[ComponentDirection].clean!
          break
        end
      when :up
        if block[ComponentPosition].x == entity[ComponentPosition].x and block[ComponentPosition].y == entity[ComponentPosition].y - 1
          observer.notify(:collision, entity, block)
          entity[ComponentDirection].clean!
          break
        end
      when :down
        if  block[ComponentPosition].x == entity[ComponentPosition].x and block[ComponentPosition].y == entity[ComponentPosition].y + 1
          observer.notify(:collision, entity, block)
          entity[ComponentDirection].clean!
          break
        end
      end
    }
    entity[ComponentDirection].clean! if entity[ComponentStep] and entity[ComponentStep].steps == 0
    case entity[ComponentDirection].direction
    when :right
      entity[ComponentPosition].x += 1 if entity[ComponentPosition].x + 1 < userdata[:screen][:cols]
    when :left
      entity[ComponentPosition].x -= 1 if entity[ComponentPosition].x - 1 > 0
    when :up
      entity[ComponentPosition].y -= 1 if entity[ComponentPosition].y - 1 > 0
    when :down
      entity[ComponentPosition].y += 1 if entity[ComponentPosition].y + 1 < userdata[:screen][:rows]
    end

    #guard steps
    entity[ComponentStep].dec if entity[ComponentStep]

  }
  
}

### MAIN


X = SDL2::Video::Window::SDL_WINDOWPOS_CENTERED
Y = SDL2::Video::Window::SDL_WINDOWPOS_CENTERED
W = 256
H = 256
$quit = false

SDL2::init
begin
  SDL2::Video::init
  begin
    w = SDL2::Video::Window.new "test1", X, Y, W, H, SDL2::Video::Window::SDL_WINDOW_SHOWN
    renderer = SDL2::Video::Renderer.new(w)

    sheet = BasicSheet.new(renderer, "sheet.bmp", 256, 96, 16)
    map = BasicMap.new(sheet, $maps[:lost_ruby][:data], $maps[:lost_ruby][:objects])
    
    map.build(EntityManager.instance, ComponentManager.instance, sheet)
    
    #build player
    EntityManager.instance.build {|eid|
      ComponentManager.instance.set(eid, ComponentSystemEvent.new)
      ComponentManager.instance.set(eid, ComponentDirection.new(:right))
      ComponentManager.instance.set(eid, ComponentPosition.new(5, 5))
      ComponentManager.instance.set(eid, ComponentSolid.new)
      ComponentManager.instance.set(eid, ComponentPlayer.new(SDL2::Input::Keyboard::SDL_SCANCODE_8, SDL2::Input::Keyboard::SDL_SCANCODE_5, SDL2::Input::Keyboard::SDL_SCANCODE_4, SDL2::Input::Keyboard::SDL_SCANCODE_6, SDL2::Input::Keyboard::SDL_SCANCODE_0))
      ComponentManager.instance.set(eid, ComponentAvatar.new({
                                                               standing: AnimateFrame.new([[0, 4]]),
                                                               walking_right: AnimateFrame.new([[4, 4], [5, 4], [6, 4]]),
                                                               walking_left: AnimateFrame.new([[4, 4], [5, 4], [6, 4]], mirror: true),
                                                               walking_up: AnimateFrame.new([[8, 4], [9, 4]]),
                                                               walking_down: AnimateFrame.new([[3, 4], [4, 4]]),
                                                             })
                                   )
    }
    

    while !$quit

      while !(ev = SDL2::Input::poll).nil?
        if ev.type == SDL2::Input::SDL_QUIT then
          $quit = true; break
        end
        ComponentManager.instance.select{|entity| entity[ComponentSystemEvent]}.each{|entity|
          entity[ComponentSystemEvent].events << ev
        }
      end
      
      renderer.draw_color = SDL2::RGB.new(0, 0, 0)
      renderer.clear
      
      SystemManager.instance.run { |userdata, observer|
        map.blit(renderer)
        ComponentManager.instance.select{|entity| entity[ComponentFrameSheet] and entity[ComponentPosition]}.each{|entity|
          sheet.blit(entity[ComponentFrameSheet].x, entity[ComponentFrameSheet].y,
                     renderer,
                     SDL2::Point.new(entity[ComponentPosition].x, entity[ComponentPosition].y)
                    )
        }

        
        ComponentManager.instance.select{|entity| entity[ComponentAvatar] and entity[ComponentPosition] and entity[ComponentDirection]}.each{|entity|

          userdata[entity] ||=  {}
          case entity[ComponentDirection].direction
          when :left
            userdata[entity][:anim] = entity[ComponentAvatar].frames[:walking_left]
          when :right
            userdata[entity][:anim] = entity[ComponentAvatar].frames[:walking_right]
          when :up
            userdata[entity][:anim] = entity[ComponentAvatar].frames[:walking_up]
          when :down
            userdata[entity][:anim] = entity[ComponentAvatar].frames[:walking_down]
          end
          userdata[entity][:anim] = entity[ComponentAvatar].frames[:standing] if userdata[entity][:anim].nil?
          userdata[entity][:anim].render(sheet, renderer, entity[ComponentPosition])
        }

        
      }
        
      renderer.present
    end
    
    renderer.destroy
    w.destroy
  ensure
    SDL2::Video::quit
  end
rescue Exception => e
  puts e
  puts e.backtrace
ensure
  exit 0
end

