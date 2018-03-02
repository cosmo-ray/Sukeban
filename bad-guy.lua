function phqFSAddGuy(main, fScreen, widSize, badGuy)
   local rect = Entity.new_array()

   fScreen:pop_back() -- life bar
   fScreen:pop_back() -- life text
   fScreen:pop_back() -- image
   fScreen.ent.background = "The_work.png"
   fScreen.ent.badGuy = badGuy
   local txt = fScreen:new_text(1, 1, Entity.new_string("life"))
   local rect = Entity.new_array()
   rect[0] = Pos.new(badGuy.life:to_int(), 10).ent;
   rect[1] = "rgba: 0 255 0 255";
   local bar = fScreen:new_rect(0, 0, rect)

   local pos = Pos.new(300 -
			  (txt:size():x() + bar:size():x()) / 2, 1)
   txt:move(pos)
   pos = Pos.new(txt:pos():x() + txt:size():x(), 1)
   bar:move(pos)
end

function dealDmg(fScreen, dmg)
   local enemyLife = fScreen.badGuy.life:to_int()

   enemyLife = enemyLife - dmg
   fScreen.badGuy.life = enemyLife
   CanvasObj.wrapp(fScreen.objs[1]):force_size(Pos.new(enemyLife, 10))
   if enemyLife <= 0 then
      return true
   end
   return false
end

function phqFSAttackGuy(entity)
   local mainMenu = Entity.wrapp(ywCntWidgetFather(entity))
   local main = Entity.wrapp(ywCntWidgetFather(mainMenu:cent()))

    startAnimation(main:cent(), Entity.new_func("guyAttackAnim"), "cur_anim")

end

function guyAttackAnim(main, anim)
    anim = Entity.wrapp(anim)
   main = Entity.wrapp(main)
   local fScreen = Entity.wrapp(main).fightScreen

   if anim.animation_frame < 1 then
      local fScreen = main.fightScreen
      if main.guy.attack(main:cent(), main.guy:cent(), fScreen.badGuy:cent()) == Y_TRUE then
        anim.is_dead = 1
       else
        anim.is_dead = 0
       end
       if main.guy.no_energy:to_int() == 1 then
        anim.last = 50
        Canvas.wrapp(fScreen):new_text(50, 50,
        Entity.new_string("No energy, go home, take a nap"))
       else
        anim.last = 10
        Canvas.wrapp(fScreen):new_img(0, 0, "Slash.png")
       end
   end

   if anim.animation_frame > anim.last:to_int() then
        Canvas.wrapp(fScreen):pop_back()
        if anim.is_dead:to_int() == 1 then
            main.guy.money = main.guy.money + 10
            update_money(main)
            swapToHouse(main.menuCnt.entries[0]:cent())
            endAnimation(main, "cur_anim")
        else
            startAnimation(main:cent(), Entity.new_func("workAttackAnim"), "cur_anim")
        end
        return Y_FALSE
    end
    return Y_TRUE
end

function workAttackAnim(main, anim)
    anim = Entity.wrapp(anim)
   main = Entity.wrapp(main)

   if anim.animation_frame < 1 then
      local fScreen = main.fightScreen
      fScreen.badGuy.attack(main:cent(), fScreen.badGuy:cent())
      Canvas.wrapp(fScreen):new_img(0, 0, "Lunge_Thrust.png")

   end

   if anim.animation_frame > 10 then
    local fScreen = main.fightScreen
    Canvas.wrapp(fScreen):pop_back()
      endAnimation(main, "cur_anim")
      if main.guy.hygien <= 0 then
	 swapToHouse(main.menuCnt.entries[0]:cent())
      end
      return Y_FALSE
   end
   return Y_TRUE
end

function attackOfTheWork(main, badGuy)
   main = Entity.wrapp(main)

   statAdd(main.guy, "hygien", -5)
end

function dmg_modifier(main)
    local dmg = 1
    if main.guy.fun > 50 then dmg = dmg + 1
    end
    if main.guy.hygien < 20 then dmg = dmg - 0.5
    end
    
    return dmg
end
    
function attackTheWork(main, goodGuy, badGuy)
   goodGuy = Entity.wrapp(goodGuy)
   badGuy = Entity.wrapp(badGuy)
   main = Entity.wrapp(main)

   statAdd(main.guy, "energy", -5)
   if main.guy.energy > 0 then
    main.guy.no_energy = 0
    if dealDmg(main.fightScreen, 10 * dmg_modifier(main)) then
          return Y_TRUE
       end
    return Y_FALSE
   else
    main.guy.no_energy = 1
   end

end
