
function victoryScreenAction(vs, eve)
   eve = Event.wrapp(eve)

   while eve:is_end() == false do
      print("loop")
      if eve:type() == YKEY_DOWN then
	 if eve:key() == Y_ENTER_KEY then
	    print("enter")
	    if yeGetString(after_fight_action) == "CombatDialogueNext" then
	       ywCntPopLastEntry(main_widget)
	    else
	       backToGame(vs)
	    end
	    return YEVE_ACTION
	 end
      end
      eve = eve:next()
   end
   return YEVE_NOTHANDLE
end

function autoLoot(main, pj, txt)
   local nb = yuiRand() % 15
   addObject(main, pj, "money", nb)
   return txt .. math.floor(nb) .. ": " .. "money" .. "\n"
end

function pushNewVictoryScreen(main, winner, looser)
   local victoryScreen = Entity.new_array()
   local txt = "tatatata ta ta ta tata\nloot:\n"
   local loot = looser.loot

   print(loot)
   if loot then
      if yeType(loot) == YSTRING then
	 if loot:to_string() == "auto" then
	    txt = autoLoot(main, winner, txt)
	 elseif loot:to_string() ~= "none" then
	    txt = txt .. "1: " .. loot:to_string() .. "\n"
	    addObject(main, winner, loot:to_string(), 1)
	 end
      elseif yeType(loot) == YARRAY then
	 local i = 0
	 while i < yeLen(loot) do
	    if yeGetKeyAt(loot, i) then
	       print(yeGetKeyAt(loot, i))
	       txt = txt .. math.floor(yeGetIntAt(loot, i)) .. ": " ..
		  yeGetKeyAt(loot, i) .. "\n"
	       addObject(main, winner, yeGetKeyAt(loot, i), yeGetIntAt(loot, i))
	    else
	       if yeGetStringAt(loot, i) == "auto" then
		  txt = autoLoot(main, winner, txt)
	       else
		  txt = txt .. "1: " .. yeGetStringAt(loot, i) .. "\n"
		  addObject(main, winner, yeGetStringAt(loot, i), 1)
	       end
	    end
	    i = i + 1
	 end
      end
   else
      txt = autoLoot(main, winner, txt)
   end

   local xp_win = yuiRand() % 5 + 1
   winner.xp = winner.xp + xp_win
   txt = txt .. "xp: " .. math.floor(xp_win) .. "\n"
   victoryScreen["<type>"] = "text-screen"
   victoryScreen["text-align"] = "center"
   victoryScreen.text = txt
   victoryScreen.background = "rgba: 155 155 255 190"
   victoryScreen.action = Entity.new_func("victoryScreenAction")
   ywPushNewWidget(main, victoryScreen)
end
