class Player
  
  def check_for(action)
    unless @warrior.respond_to?(action)
      eval "play_without_#{action}"
      @health = @warrior.health 
      return true
    end
  end
  
  def at_distance?(direction, space)
    @warrior.look(direction)[1].send(space) || (@warrior.look(direction)[1].empty? && @warrior.look(direction)[2].send(space))
  end
  
  def wall?(direction)
    @warrior.feel.wall? || (at_distance?(direction, :wall?) && !@warrior.feel.stairs? && !at_distance?(direction, :stairs?))
  end

  def wall_infront?
    wall?(:forward)
  end

  def captive_at_distance?(direction)
    at_distance?(direction, :captive?)
  end
   
  def enemy_at_distance?(direction)
    at_distance?(direction, :enemy?)
  end
    
  def enemy_behind_at_distance?
    enemy_at_distance?(:backward)
  end
    
  def enemy_infront_at_distance?
    enemy_at_distance?(:forward)
  end
    
  def make(action, direction=nil)
    @action = action
    puts "Action: #{@action} #{direction}"
    if direction
      @warrior.send(action, direction)
    else
      @warrior.send(action)
    end
  end
  
  def check_action_for_feel(action, space, directions, &block)
    directions.each do |direction|
      if @warrior.feel(direction).send(space)
        if block_given?
          block.call(direction)
        else
          make(action, direction)
        end
        return true
      end
    end
    return false
  end
  
  def bind_enemy_if_nearby(directions = [:right, :backward, :left, :forward])
    return false if @bound.length > 2
    check_action_for_feel(:bind!, :enemy?, directions) do |direction|
      puts "Binding enemy"
      @bound << direction
      make(:bind!, direction)
    end
  end

  def attack_enemy_if_nearby(directions = [:right, :backward, :left, :forward])
    check_action_for_feel(:attack!, :enemy?, directions)
  end
  
  def save_captive_if_nearby(directions = [:right, :backward, :left, :forward])
    check_action_for_feel(:rescue!, :captive?, directions) do |direction|
      if @bound.include?(direction)
        puts "Attacking bound enemy"
        @bound.delete_if {|x| x == direction }
        make(:attack!, direction)
      else
        puts "Rescuing Captive"
        make(:rescue!, direction)
      end
    end
  end
  
  def heal_if_bound_enemy_nearby
    puts "Healing near bound enemy"
    if !@bound.empty? && @warrior.health < 19
      puts "Healing near bound enemy"
      make(:rest!)  
    end
  end

  def alternatives(direction)
    case direction
    when :forward
      [:left, :right, :backward]
    when :backward
      [:right, :left, :forward]
    when :left
      [:backward, :forward, :right]
    when :right
      [:forward, :backward, :left]
    end 
  end

  def divert(direction)
    puts "Diverting"
    alternatives(direction).each do |d|
      if @warrior.feel(d).empty?
        return make(:walk!, d)
      end
    end
  end

  def head_to(type)
    @warrior.listen.each do |space|
      if space.send(type)
        direction = @warrior.direction_of(space)
        case @warrior.feel(direction)
        when :stairs?
          puts "Heading to any empty space targetting #{type}"
          return divert(direction) 
        else
          puts "Heading to empty space targetting #{type}"
          return make(:walk!, direction)
        end
      end
    end 
    return false 
  end
  
  def handle_ticking_bomb
    @warrior.listen.each do |space|
      if space.ticking?
        direction = @warrior.direction_of(space)
        puts "Handling ticking bomb at #{direction}"
        case 
        when bind_enemy_if_nearby(alternatives(direction))
        when attack_enemy_if_nearby
        when @warrior.feel(direction).captive?
          return make(:rescue!, direction)
        else
          @bound = []
          head_to(:ticking?)
        end
        return true
      end
    end
    return false
  end

  def head_to_captive
    head_to(:captive?)
  end
  
  def head_to_enemy
    head_to(:enemy?)    
  end
  
  def heal
    if @warrior.health < 20 && @health <= @warrior.health
      puts "Healing"
      make(:rest!)
    else
      return false
    end
  end

  def play_turn(warrior)
    @warrior = warrior

    unless @warrior.respond_to?(:health)
      play_without_health 
      return
    end  

    @health ||= @warrior.health 
    @action ||= :walk!
    @bound ||= []
     
    puts "Old Health: #{@health}" if @health
    puts "New Health: #{@warrior.health}"
    puts "Value of action: #{@action}"
    puts "Bound Enemies: #{@bound}"

    case
    when handle_ticking_bomb
    when bind_enemy_if_nearby
    when save_captive_if_nearby
    when heal_if_bound_enemy_nearby
    when attack_enemy_if_nearby
    when heal
    when head_to_captive
    when head_to_enemy
    else
      make(:walk!, @warrior.direction_of_stairs)
    end

    @health = @warrior.health
  end
  
  def play_without_health
    puts "Playing without health method"
    
    unless @warrior.respond_to?(:attack!)
      play_without_attack
      return
    end
    
    case
    when attack_enemy_if_nearby
    else
      make(:walk!, @warrior.direction_of_stairs)
    end
  end

  def play_without_attack
    puts "Playing without attack method"
    make(:walk!, @warrior.direction_of_stairs)
  end
end
