PIX_PER_FRAME = 6
local ACTION_MOVE = 1

local LPCS_LEFT = 9
local LPCS_DOWN = 10
local LPCS_RIGHT = 11
local LPCS_UP = 8

ACTION_NPC = 0
local ACTION_MV_TBL = 1
local ACTION_MV_TBL_IDX = 2

local ENEMY_IDLE = 0
local ENEMY_ATTACKING = 1

function npcAdvenceTime()
   main_widget.npc_act = {}
   for i = 0, yeLen(npcs) do
      local n = npcs[i]

      if yIsNil(n) then
	 goto skip
      end

      local ai = n.ai
      if ai then
	 Entity.new_func(yeGetString(ai))(main_widget, n, yeGetKeyAt(npcs, i))
      end
      :: skip ::
   end
end

local function npc_check_col(canvas, col_r, pos_add)
   local ret = false
   local cols = ywCanvasProjectedArColisionArray(canvas, col_r, pos_add)
   print("cols", cols, yeLen(cols), pos_add)
   local i = 0
   while i < yeLen(cols) do
      local col = yeGet(cols, i)

      print("does Collision:", yeGetIntAt(col, "Collision"))
      if yIsNil(yeGet(col, "is_npc")) and yeGetIntAt(col, "Collision") ~= 0 then
	 ret = true
	 break
      end

      i = i + 1
   end
   yeDestroy(cols)
   return ret
end

local function searching(wid, enemy)
      local pos = ylpcsHandePos(enemy)
      local orig_pos = enemy.orig_pos
      local pj_pos = ylpcsHandePos(wid.pj)
      local pj_dist = ywPosDistance(pos, pj_pos)
      local up_down = 0
      local left_right = 0
      local is_attacking = false
      local colRect = Rect.new(ywPosX(pos) + 10, ywPosY(pos) + 30, 20, 20).ent

      if pj_dist > 300 then
	 return nil
      end

      if yeGetInt(enemy.ai_state) == ENEMY_ATTACKING then
	 is_attacking = true
      end
      print("ENEMY TURN !!!!")
      print("enemy lpcs pos:", enemy.y, LPCS_LEFT, LPCS_RIGHT, LPCS_UP,
	    LPCS_DOWN)
      if ywPosX(pj_pos) > ywPosX(pos) then
	 if (is_attacking == false and enemy.y:to_int() == LPCS_LEFT) then
	    return nil
	 end
	 left_right = 1
      elseif ywPosX(pj_pos) < ywPosX(pos) then
	 if (is_attacking == false and enemy.y:to_int() == LPCS_RIGHT) then
	    return nil
	 end
	 left_right = -1
      end
      if ywPosY(pj_pos) > ywPosY(pos) then
	 if (is_attacking == false and enemy.y:to_int() == LPCS_UP) then
	    return nil
	 end
	 up_down = 1
      elseif ywPosY(pj_pos) < ywPosY(pos) then
	 if (is_attacking == false and enemy.y:to_int() == LPCS_DOWN) then
	    return nil
	 end
	 up_down = -1
      end

      local y_dist = math.abs(ywPosY(pos) - ywPosY(pj_pos))
      local x_dist = math.abs(ywPosX(pos) - ywPosX(pj_pos))
      if false then
	 local x_acc = 0
	 local y_acc = 0

	 while x_acc + 10 < x_dist and y_acc + 10 < y_dist do
	    x_acc = x_acc + 10
	    y_acc = y_acc + 10
	 end
	 while x_acc + 10 < x_dist do
	    x_acc = x_acc + 10
	 end
	 while y_acc + 10 < y_dist do
	    y_acc = y_acc + 10
	 end
      end
      local mvx = pix_mv
      local mvy = pix_mv
      if x_dist < mvx then
	 mvx = x_dist
      end
      if y_dist < mvy then
	 mvy = y_dist
      end
      local ret = Pos.new(mvx * left_right, mvy * up_down).ent
      if npc_check_col(wid.mainScreen, colRect, ret) then
	 if x_dist > y_dist then
	    ret = Pos.new(mvx * left_right, 0).ent
	    if npc_check_col(wid.mainScreen, colRect, ret) == false then
	       return ret
	    end
	    ret = Pos.new(mvx * left_right, -mvy * up_down).ent
	    if npc_check_col(wid.mainScreen, colRect, ret) == false then
	       return ret
	    end
	    ret = Pos.new(0, mvy * up_down).ent
	    if npc_check_col(wid.mainScreen, colRect, ret) == false then
	       return ret
	    end
	 else
	    ret = Pos.new(0, mvy * up_down).ent
	    if npc_check_col(wid.mainScreen, colRect, ret) == false then
	       return ret
	    end
	    ret = Pos.new(-mvx * left_right, mvy * up_down).ent
	    if npc_check_col(wid.mainScreen, colRect, ret) == false then
	       return ret
	    end
	    ret = Pos.new(mvx * left_right, 0).ent
	    if npc_check_col(wid.mainScreen, colRect, ret) == false then
	       return ret
	    end
	 end
	 return nil
      end
      return ret
end

function saveNpcCanvasMatadata(dst, npc_canvas)
   dst = Entity.wrapp(dst)
   npc_canvas = Entity.wrapp(npc_canvas)

   dst.Collision = npc_canvas.Collision
   dst.is_npc = npc_canvas.is_npc
   dst.dialogue = yeGetString(npc_canvas.dialogue)
   dst.current = npc_canvas.current
   dst.agresive = npc_canvas.agresive
   dst.st = npc_canvas.small_talk
   dst.dc = npc_canvas.dialogue_condition
end

function restoreNpcCanvasMatadata(npc_canvas, src)
   src = Entity.wrapp(src)
   npc_canvas = Entity.wrapp(npc_canvas)

   npc_canvas.Collision = src.Collision
   npc_canvas.is_npc = src.is_npc
   npc_canvas.dialogue = src.dialogue
   npc_canvas.current = src.current
   npc_canvas.agresive = src.agresive
   npc_canvas.small_talk = src.st
   npc_canvas.dialogue_condition = src.dc
end

function NpcTurn(wid)
   local i = 0
   local npc_act = wid.npc_act
   local nb_na = yeLen(npc_act)

   while i < nb_na do
      if npc_act[i] then
	 wid.npc_act[i].controller(wid, npc_act[i])
      end
      i = i + 1
   end
   i = 0
   while i < yeLen(wid.enemies) do
      local enemy = wid.enemies[i]
      local mv_pos = searching(wid, enemy)

      if (mv_pos and yuiRand() % 2) then
	 local ec = enemy.canvas
	 local tmp = Entity.new_array()

	 saveNpcCanvasMatadata(tmp, ec)
	 enemy.ai_state = ENEMY_ATTACKING
	 if math.abs(ywPosX(mv_pos)) > math.abs(ywPosY(mv_pos)) and
	    (enemy.y:to_int() == LPCS_UP or enemy.y:to_int() == LPCS_DOWN) then
	       if ywPosX(mv_pos) > 0 then
		  lpcs.handlerSetOrigXY(enemy, 0, LPCS_RIGHT)
	       else
		  lpcs.handlerSetOrigXY(enemy, 0, LPCS_LEFT)
	       end
	 elseif math.abs(ywPosX(mv_pos)) < math.abs(ywPosY(mv_pos)) and
	 (enemy.y:to_int() == LPCS_LEFT or enemy.y:to_int() == LPCS_RIGHT) then
	    if ywPosY(mv_pos) > 0 then
	       lpcs.handlerSetOrigXY(enemy, 0, LPCS_DOWN)
	    else
	       lpcs.handlerSetOrigXY(enemy, 0, LPCS_UP)
	    end
	 else
	    ylpcsHandlerNextStep(enemy)
	 end
	 ylpcsHandlerRefresh(enemy)
	 ylpcsHandlerMove(enemy, mv_pos)
	 ec = enemy.canvas
	 restoreNpcCanvasMatadata(ec, tmp)
      end
      i  = i + 1
   end
end

local  PjLeaveController_t = 0
function PjLeaveController(wid, action)
   PjLeaveController_t = PjLeaveController_t  + ywidGetTurnTimer()
   if PjLeaveController_t > 10000 then
      PjLeaveController_t = 0
   else
      return
   end
   wid = Entity.wrapp(wid)
   action = Entity.wrapp(action)
   local mv_tbl_idx = action[ACTION_MV_TBL_IDX]
   local mvPos = action[ACTION_MV_TBL][mv_tbl_idx:to_int()]
   local npc = action[ACTION_NPC]
   if yIsNil(npc) or npc.char == nil then
      return
   end
   local curPos = generic_handlerPos(npc)
   local dif_x = ywPosX(mvPos) - ywPosX(curPos)
   local dif_y = ywPosY(mvPos) - ywPosY(curPos)
   action[ACTION_MV_TBL_IDX] = action[ACTION_MV_TBL_IDX] + 1

   if mvPos == nil then
      local end_f = action.end_f
      if (end_f) then
	 end_f(wid, npc)
      else
	 ywCanvasRemoveObj(npc.wid, npc.canvas)
	 yeRemoveChild(main_widget.npcs, npc)
      end
      yeRemoveChild(wid.npc_act, action)
      return
   end
   -- if checkcolision still todo:
   npc.move.left_right = 1
   if math.abs(dif_y) == 0 then
      if dif_x > 0 then
	 npc.y = LPCS_RIGHT
      else
	 npc.y = LPCS_LEFT
      end
   end
   if math.abs(dif_x) == 0 then
      if dif_y < 0 then
	 npc.y = LPCS_UP
      else
	 npc.y = LPCS_DOWN
      end
   end
   local tmp = Entity.new_array()
   saveNpcCanvasMatadata(tmp, npc.canvas)
   if yeGetString(npc.char.type) == "sprite" then
      --print("npc.y: ", yeGetInt(npc.y), " - ", LPCS_LEFT, LPCS_UP, LPCS_RIGHT, LPCS_DOWN, yeGetInt(npc.y) == LPCS_DOWN)
      if yeGetInt(npc.y) == LPCS_LEFT then
	 yeSetAt(npc, "y_offset", 96)
      elseif yeGetInt(npc.y) == LPCS_RIGHT then
	 yeSetAt(npc, "y_offset", 32)
      elseif yeGetInt(npc.y) == LPCS_DOWN then
	 yeSetAt(npc, "y_offset", 64)
      else -- y offset is 0 for "up"
	 yeSetAt(npc, "y_offset", 0)
      end

      sprite_man.handlerSetPos(npc, mvPos)
      sprite_man.handlerRefresh(npc)
   else
      walkDoStep(wid, npc)
      ylpcsHandlerSetPos(npc, mvPos)
   end
   restoreNpcCanvasMatadata(npc.canvas, tmp)
end

function NpcGoToTbl(npc, tbl, end_f)
   local main = main_widget
   local action = Entity.new_array()
   local rdst = Rect.new(ywPosX(dest_pos), ywPosY(dest_pos), 1, 1)
   npc = Entity.wrapp(npc)

   if speed == nil then
      speed = 1
   end

   npc.move = {}
   action[ACTION_NPC] = npc
   action[ACTION_MV_TBL] = tbl
   action[ACTION_MV_TBL_IDX] = 0

   if end_f then
      action.end_f = end_f
   end

   action.controller = Entity.new_func("PjLeaveController")
   if main.npc_act == nil then
      main.npc_act = {}
   end
   yePush(main.npc_act, action)
end

function NpcGoTo(npc, dest_pos, speed, end_f)
   local tbl = Entity.new_array()

   if speed == nil then
      speed = 1
   end
   ywCanvasDoPathfinding(main_widget.mainScreen, ywCanvasObjPos(npc.canvas),
			 dest_pos,
			 Pos.new(PIX_PER_FRAME * speed, PIX_PER_FRAME * speed).ent,
			 tbl)
   NpcGoToTbl(npc, tbl, end_f)
end

function pushPjLeave(npc, entryPoint)
   local main = main_widget
   if main.npc_act == nil then
      main.npc_act = {}
   end
   local action = Entity.new_array(main.npc_act)
   local exit = main.exits[yeGetInt(entryPoint)]

   npc.move = {}
   action[ACTION_NPC] = npc
   action[ACTION_MV_TBL] = {}
   action[ACTION_MV_TBL_IDX] = 0
   print(exit.rect, yeGetInt(entryPoint))
   ywCanvasDoPathfinding(main.mainScreen, ywCanvasObjPos(npc.canvas), exit.rect,
			 Pos.new(PIX_PER_FRAME, PIX_PER_FRAME).ent,
			 action[ACTION_MV_TBL])
   print(action.mv_table)
   action.controller = Entity.new_func("PjLeaveController")
end

function PjLeave(owid, eve, entryPoint)
   wid = Entity.wrapp(yDialogueGetMain(owid))
   local main = Entity.wrapp(ywCntWidgetFather(wid))
   local npc = main.npcs[wid.npc_nb:to_int()]
   if main.npc_act == nil then
      main.npc_act = {}
   end

   local action = Entity.new_array(main.npc_act)
   local exit = main.exits[yeGetInt(entryPoint)]
   npc.move = {}
   action[ACTION_NPC] = npc
   action[ACTION_MV_TBL] = {}
   action[ACTION_MV_TBL_IDX] = 0
   ywCanvasDoPathfinding(main.mainScreen, ywCanvasObjPos(npc.canvas), exit.rect,
		      Pos.new(PIX_PER_FRAME, PIX_PER_FRAME).ent,
		      action[ACTION_MV_TBL])
   action.controller = Entity.new_func("PjLeaveController")
   backToGame(owid, eve, arg)
end
