
MODE_NO_TACTICAL_FIGHT = 0
MODE_TACTICAL_FIGHT_INIT = 1
local MODE_PLAYER_TURN = 2

TACTICAL_FIGHT_MODE = MODE_NO_TACTICAL_FIGHT

local function end_fight()
   TACTICAL_FIGHT_MODE = MODE_NO_TACTICAL_FIGHT
end

function do_tactical_figght(eve)
   if TACTICAL_FIGHT_MODE == MODE_TACTICAL_FIGHT_INIT then
      printMessage(main_widget, nil,
		   "TACTICAL FIGHT MODE START, unimlemented press 'ESC' to quit")
      TACTICAL_FIGHT_MODE = MODE_PLAYER_TURN
   end

   if yevIsKeyDown(eve, Y_ESC_KEY) then
      return end_fight()
   end

   print("do Tactical Fight")
end
