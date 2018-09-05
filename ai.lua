local PIX_PER_FRAME = 6
local ACTION_MOVE = 1

local LPCS_LEFT = 9
local LPCS_DOWN = 10
local LPCS_RIGHT = 11
local LPCS_UP = 8

local ACTION_NPC = 0
local ACTION_MV_TBL = 1
local ACTION_MV_TBL_IDX = 2

function NpcTurn(wid)
   local i = 0
   local npc_act = wid.npc_act
   while i < yeLen(npc_act) do
      wid.npc_act[i].controller(wid, npc_act[i])
      i = i + 1
   end
end

function PjLeaveController(wid, action)
   wid = Entity.wrapp(wid)
   action = Entity.wrapp(action)
   local mv_tbl_idx = action[ACTION_MV_TBL_IDX]
   local mvPos = action[ACTION_MV_TBL][mv_tbl_idx:to_int()]
   local npc = action[ACTION_NPC]
   local curPos = ylpcsHandePos(npc)
   local dif_x = ywPosX(mvPos) - ywPosX(curPos)
   local dif_y = ywPosY(mvPos) - ywPosY(curPos)
   action[ACTION_MV_TBL_IDX] = action[ACTION_MV_TBL_IDX] + 1

   if mvPos == nil then
      ywCanvasRemoveObj(npc.wid, npc.canvas)
      yeRemoveChild(wid.npc_act, action)
      return
   end
   -- if checkcolision still todo:
   npc.move.left_right = 1
   if yuiAbs(dif_x) > yuiAbs(dif_y) then
      if dif_x > 0 then
	 npc.y = LPCS_RIGHT
      else
	 npc.y = LPCS_LEFT
      end
   else
      if dif_y < 0 then
	 npc.y = LPCS_UP
      else
	 npc.y = LPCS_DOWN
      end
   end
   walkDoStep(wid, npc)
   ylpcsHandlerSetPos(npc, mvPos)
end

function PjLeave(owid, eve, arg, entryPoint)
   wid = Entity.wrapp(yDialogueGetMain(owid))
   local main = Entity.wrapp(ywCntWidgetFather(wid))
   local npc = main.npcs[wid.npc_nb:to_int()]
   local action = Entity.new_array(main.npc_act)
   local exit = main.exits[yeGetInt(entryPoint)]
   npc.move = {}
   action[ACTION_NPC] = npc
   action[ACTION_MV_TBL] = {}
   action[ACTION_MV_TBL_IDX] = 0
   print(exit.rect, yeGetInt(entryPoint))
   ywCanvasDoPathfinding(main.mainScreen, npc.canvas, exit.rect,
		      Pos.new(PIX_PER_FRAME, PIX_PER_FRAME).ent,
		      action[ACTION_MV_TBL])
   print(action.mv_table)
   action.controller = Entity.new_func("PjLeaveController")
   EndDialog(owid, eve, arg)
end
