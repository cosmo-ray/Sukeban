
MODE_NO_TACTICAL_FIGHT = 0
MODE_TACTICAL_FIGHT_INIT = 1
local MODE_PLAYER_TURN = 2

TACTICAL_FIGHT_MODE = MODE_NO_TACTICAL_FIGHT

local function end_fight()
   TACTICAL_FIGHT_MODE = MODE_NO_TACTICAL_FIGHT
end

function do_tactical_fight(eve)
   local tdata = main_widget.tactical
   if TACTICAL_FIGHT_MODE == MODE_TACTICAL_FIGHT_INIT then
      printMessage(main_widget, nil,
		   "TACTICAL FIGHT MODE START, unimlemented press 'ESC' to quit")
      TACTICAL_FIGHT_MODE = MODE_PLAYER_TURN
      local args = tdata.args

      for i = 0, yeLen(args) - 1 do
	 local k = yeGetKeyAt(args, i)
	 local a = args[i]

	 if k == "add-enemies" then
	    for j = 0, yeLen(a) - 1 do
	       print("place enemie: ", a[j])
	       npc = a[j]

	       local npcp = Pos.new(yeGetIntAt(npc, 0), yeGetIntAt(npc, 1))
	       local npcn = yeGetStringAt(npc, 2)
	       local npcd = lpcsStrToDir(yeGetStringAt(npc, 3))

	       push_npc(npcp, npcn, npcd)
	    end
	 end
      end
   end

   if yevIsKeyDown(eve, Y_ESC_KEY) then
      return end_fight()
   end

   reposeCam(main_widget)
   return YEVE_ACTION
end
