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
  
  def check_action_for_feel(action, space, &block)
    [:forward, :left, :right, :backward].each do |direction|
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

  def bind_enemy_if_nearby
    check_action_for_feel(:bind!, :enemy?) do |direction|
      @bound << direction
      make(:bind!, direction)
    end
  end

  def attack_enemy_if_nearby
    check_action_for_feel(:attack!, :enemy?)
  end
  
  def save_captive_if_nearby
    check_action_for_feel(:rescue!, :captive?) do |direction|
      if @bound.include?(direction)
        @bound.delete_if {|x| x == direction }
        make(:attack!, direction)
      else
        make(:rescue!, direction)
      end
    end
  end
  
  def heal_if_bound_enemy_nearby
    if !@bound.empty? && @warrior.health < 20
      make(:rest!)  
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
    when bind_enemy_if_nearby
    when heal_if_bound_enemy_nearby
    when attack_enemy_if_nearby
    when save_captive_if_nearby
    when @warrior.health < 20 && @health <= @warrior.health
      make(:rest!)
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
