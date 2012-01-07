class Player
  def play_turn(warrior)
    @warrior = warrior

    unless @warrior.respond_to?(:health)
      play_without_health 
      return
    end
     
    @health ||= @warrior.health 
    @action ||= :walk!
    
    puts "Old Health: #{@health}" if @health
    puts "New Health: #{@warrior.health}"
    puts "Value of action: #{@action}"
    
    def check_for(action)
      unless @warrior.respond_to?(action)
        eval "play_without_#{action.to_s}"
        @health = @warrior.health 
        return
      end
    end
    
    check_for :pivot!
    check_for :look
    
    def at_distance?(direction, space)
      eval "@warrior.look(:#{direction})[1].#{space} || (@warrior.look(:#{direction})[1].empty? && @warrior.look(:#{direction})[2].#{space})"
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
    
    def make(action)
      @action = action
      @warrior.send(action)
    end
    
    case
    when @warrior.feel.enemy?
      make :attack!
    when @warrior.feel.captive?
      make :rescue!
    when wall_infront?
      make :pivot!
    when !enemy_infront_at_distance? && enemy_behind_at_distance?
      make :pivot!
    when enemy_infront_at_distance? && enemy_behind_at_distance?
      make :walk!
    when enemy_infront_at_distance? && !enemy_behind_at_distance?
      make :shoot!
    when @warrior.health < 20 && @health <= @warrior.health
      make :rest!
    when !enemy_infront_at_distance? && captive_at_distance?(:backward)
      make :pivot!
    else
      make :walk!
    end

    @health = @warrior.health
  end
  
  def play_without_look
    puts "Playing without look"
    case
    when @warrior.feel.enemy?
      @warrior.attack!
    when @warrior.feel.captive?
      @warrior.rescue!
    when @health > @warrior.health+1 && @warrior.health < 10
      @warrior.walk! :backward
    when @warrior.health < 20 && @health <= @warrior.health
      @warrior.rest!
    when @warrior.feel.wall? && @warrior.respond_to?(:pivot!)
      @warrior.pivot!
    else
      @warrior.walk! :forward
    end
  end
  
  def play_without_pivot!
    puts "Playing without pivot"
    case
    when @warrior.feel.enemy?
      @warrior.attack!
    when @warrior.feel.captive?
      @warrior.rescue!
    when @health > @warrior.health+1 && @warrior.health < 10
      @warrior.walk! :backward
    when @warrior.health < 20 && @health <= @warrior.health
      @warrior.rest!
    else
      @warrior.walk! :forward
    end
  end
 
  def play_without_health
    puts "Playing without health method"
    
    unless @warrior.respond_to?(:attack!)
      play_without_attack
      return
    end
    
    case
    when @warrior.feel.enemy?
      @warrior.attack!
    else
      @warrior.walk!
    end
  end

  def play_without_attack
    puts "Playing without attack method"
    @warrior.walk!
  end
end
