--
--Copyright (C) 2022 Matthias Gatto
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Lesser General Public License as published by
--the Free Software Foundation, either version 3 of the License, or
--(at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU General Public License for more details.
--
--You should have received a copy of the GNU Lesser General Public License
--along with this program.  If not, see <http://www.gnu.org/licenses/>.
--

local phq = Entity.wrapp(ygGet("phq"))

local function victoryScreenAction(vs, eve)
   eve = Event.wrapp(eve)

   while eve:is_end() == false do
      if eve:type() == YKEY_DOWN then
	 if eve:key() == Y_ENTER_KEY then
	    if fight_script == "CombatDialogueNext" then
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

local function autoLoot(main, pj, looser, txt)
   local max_life = yeGetInt(looser.max_life) + 3

   local nb = yuiRand() % (max_life / 2)
   addObject(main, pj, "money", nb)
   return txt .. math.floor(nb) .. "$\n"
end

function pushNewVictoryScreen(main, _unused, loosers)
   local victoryScreen = Entity.new_array()
   local txt = "tatatata ta ta ta tata\n"
   local i = 0

   while i < yeLen(loosers) do
      local looser = loosers[i]
      local loot = looser.loot

      if looser.victory_action then
	 print("cmp: ", looser.victory_action:to_string(), "increase_int",
	       looser.victory_action:to_string() == "increase_int")
	 if looser.victory_action:to_string() == "increase_int" then
	    print("ygIncreaseInt", looser.vapath)
	    ygIncreaseInt(looser.vapath:to_string(), 1)
	 else
	    print("unknow action: ", looser.victory_action)
	 end
      end
      if loot then
	 if yeType(loot) == YSTRING then
	    if loot:to_string() == "auto" then
	       txt = txt .. "loot:\n"
	       txt = autoLoot(main, phq.pj, looser, txt)
	    elseif loot:to_string() ~= "none" then
	       txt = txt .. "1: " .. loot:to_string() .. "\n"
	       addObject(main, phq.pj, loot:to_string(), 1)
	    end
	 elseif yeType(loot) == YARRAY then
	    txt = txt .. "loot:\n"

	    local j = 0
	    while j < yeLen(loot) do
	       if yeGetKeyAt(loot, j) then
		  print(yeGetKeyAt(loot, j))
		  txt = txt .. math.floor(yeGetIntAt(loot, j)) .. ": " ..
		     yeGetKeyAt(loot, j) .. "\n"
		  addObject(main, phq.pj, yeGetKeyAt(loot, j),
			    yeGetIntAt(loot, j))
	       else
		  if yeGetStringAt(loot, j) == "auto" then
		     txt = autoLoot(main, phq.pj, looser, txt)
		  else
		     txt = txt .. "1: " .. yeGetStringAt(loot, j) .. "\n"
		     addObject(main, phq.phq, yeGetStringAt(loot, j), 1)
		  end
	       end
	       j = j + 1
	    end
	 end
      end
      i = i + 1
   end

   local xp_win = yuiRand() % 5 + 1
   phq.pj.xp = phq.pj.xp + xp_win
   txt = txt .. "xp: " .. math.floor(xp_win) .. "\n"
   victoryScreen["<type>"] = "text-screen"
   victoryScreen["text-align"] = "center"
   victoryScreen.text = txt
   victoryScreen.background = "rgba: 155 155 255 190"
   victoryScreen.action = Entity.new_func(victoryScreenAction)
   ywPushNewWidget(main, victoryScreen)
end
