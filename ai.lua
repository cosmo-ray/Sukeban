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

PIX_PER_FRAME = 6
--local ACTION_MOVE = 1

ACTION_NPC = 0
local ACTION_MV_TBL = 1
local ACTION_MV_TBL_IDX = 2

local ENEMY_IDLE = 0
local ENEMY_ATTACKING = 1

local phq = Entity.wrapp(ygGet("phq"))

local function npc_check_col(canvas, col_r, pos_add)
   local ret = false
   local cols = ywCanvasProjectedArColisionArray(canvas, col_r, pos_add)
   local i = 0
   while i < yeLen(cols) do
      local col = yeGet(cols, i)

      if yIsNil(yeGet(col, "is_npc")) and yeGetIntAt(col, "Collision") ~= 0 then
	 ret = true
	 break
      end

      i = i + 1
   end
   yeDestroy(cols)
   return ret
end

function randomMovements(_osef, action)
   action = Entity.wrapp(action)
   directions = {LPCS_LEFT, LPCS_DOWN,
		 LPCS_RIGHT, LPCS_UP}
   local h = action.hdl
   local pix_mv = ywidGetTurnTimer() / 10000

   if (yIsNil(action.timer_add)) or action.timer_add > 2000 then
      if yIsNil(action.timer_add) then
	 action.hdl = main_widget.npcs[action[0]]
	 h = action.hdl
	 pix_mv = 1
      end
      action.timer_add = 0
      action.timer_left = 0
      local tmp = Entity.new_array()
      local dir = rand_array_elem(directions)
      saveNpcCanvasMatadata(tmp, h.canvas)
      yGenericSetDir(h, dir)
      action._d = dir
      yGenericHandlerRefresh(h)
      restoreNpcCanvasMatadata(h.canvas, tmp)
   end
   action.timer_add = action.timer_add + ywidGetTurnTimer() / 100
   add_x, add_y = lpcsDirToXY(action._d);
   -- do correct movement coputing here
   --local PIX_MV_PER_MS = 4
   --add_x = add_x * (PIX_MV_PER_MS / TURN_LENGTH)
   --add_y = add_y * (PIX_MV_PER_MS / TURN_LENGTH)
   local sav = pix_mv - math.floor(pix_mv)
   pix_mv = math.floor(pix_mv)
   action.timer_left = action.timer_left + sav
   if (action.timer_left > 1) then
      pix_mv = pix_mv + 1
      action.timer_left = action.timer_left - 1
   end
   add_x = add_x * pix_mv
   add_y = add_y * pix_mv

   add_pos = Pos.new(add_x, add_y)

   if npc_check_col(main_widget_screen,
		    Rect.new_ps(yGenericHandlerPos(h),
				yGenericHandlerSize(h)).ent,
		    add_pos.ent) == false then
      yGenericHandlerMoveXY(h, add_x, add_y)
   end
   --print("random movements !!!", action, ywidGetTurnTimer() / 100)
end

function npcAdvenceTime()
   main_widget.npc_act = {}
   phq.env.ai_point = {}
   local npcs_l = yeLen(npcs)
   local threshold = yuiRand()
   for i0 = 0, npcs_l - 1 do
      local i = (i0 + threshold) % npcs_l
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

local function searching(wid, enemy)
      local pos = ylpcsHandePos(enemy)
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
      local mvx = pix_mv
      local mvy = pix_mv
      if x_dist < mvx then
	 mvx = x_dist
      end
      if y_dist < mvy then
	 mvy = y_dist
      end
      local ret = Pos.new(mvx * left_right, mvy * up_down).ent
      if npc_check_col(main_widget_screen, colRect, ret) then
	 if x_dist > y_dist then
	    ret = Pos.new(mvx * left_right, 0).ent
	    if npc_check_col(main_widget_screen, colRect, ret) == false then
	       return ret
	    end
	    ret = Pos.new(mvx * left_right, -mvy * up_down).ent
	    if npc_check_col(main_widget_screen, colRect, ret) == false then
	       return ret
	    end
	    ret = Pos.new(0, mvy * up_down).ent
	    if npc_check_col(main_widget_screen, colRect, ret) == false then
	       return ret
	    end
	 else
	    ret = Pos.new(0, mvy * up_down).ent
	    if npc_check_col(main_widget_screen, colRect, ret) == false then
	       return ret
	    end
	    ret = Pos.new(-mvx * left_right, mvy * up_down).ent
	    if npc_check_col(main_widget_screen, colRect, ret) == false then
	       return ret
	    end
	    ret = Pos.new(mvx * left_right, 0).ent
	    if npc_check_col(main_widget_screen, colRect, ret) == false then
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
      local mv_pos

      if yIsNil(enemy) then
	 goto loop_next;
      end

      mv_pos = searching(wid, enemy)

      if (mv_pos and yuiRand() % 2) then
	 local ec = enemy.canvas
	 local tmp = Entity.new_array()

	 if yeGetIntAt(enemy, "ai_state") == ENEMY_IDLE then
	    enemy.mv_pix = 0
	 end

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
	    if (enemy.mv_pix > 20) then
	       enemy.mv_pix = 0
	       ylpcsHandlerNextStep(enemy)
	    else
	       enemy.mv_pix = enemy.mv_pix + ywSizeDistance(mv_pos)
	    end
	 end

	 ylpcsHandlerRefresh(enemy)
	 ylpcsHandlerMove(enemy, mv_pos)
	 ec = enemy.canvas
	 restoreNpcCanvasMatadata(ec, tmp)
      end
      :: loop_next ::
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
   local curPos = yGenericHandlerPos(npc)
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
      yGenericSetDir(npc, npc.y)
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

   action.controller = Entity.new_func(PjLeaveController)
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
   ywCanvasDoPathfinding(main_widget_screen, ywCanvasObjPos(npc.canvas),
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
   ywCanvasDoPathfinding(main_widget_screen, ywCanvasObjPos(npc.canvas),
			 exit.rect,
			 Pos.new(PIX_PER_FRAME, PIX_PER_FRAME).ent,
			 action[ACTION_MV_TBL])
   action.controller = Entity.new_func(PjLeaveController)
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
   ywCanvasDoPathfinding(main_widget_screen, ywCanvasObjPos(npc.canvas),
			 exit.rect,
			 Pos.new(PIX_PER_FRAME, PIX_PER_FRAME).ent,
			 action[ACTION_MV_TBL])
   action.controller = Entity.new_func(PjLeaveController)
   backToGame(owid, eve, arg)
end

function calsses_event_dialog_gen(_wid, cur_dialogue)
   local pj = phq.pj
   cur_dialogue = Entity.wrapp(cur_dialogue)

   if phq_pc.trait.lazy > 3 and yuiRand() % 2 == 0 then
      cur_dialogue["text"] = "You slack off durring class"
      increaseStat(nil, phq.pj.reputation, "glandeur", 1)
      return
   end
   local whos = {}
   local whos_names = {}
   local whos_nb = 1
   --local ph_year = yeGetIntAt(pj, "student_year")
   for i = 0, yeLen(npcs) - 1 do
      local npc = yeGet(npcs, i)
      local npc_names = yeGetKeyAt(npcs, i)
      if yeGetIntAt(npc, "student_year") == yeGetIntAt(pj, "student_year") and
	 yeGetIntAt(npc, "class") == yeGetIntAt(pj, "class") then
	 whos[whos_nb] = Entity.wrapp(npc)
	 whos_names[whos_nb] = npc_names
	 whos_nb = whos_nb + 1
      end
   end

   local target_i = yuiRand() % whos_nb + 1
   local target = whos[target_i]

   if yIsNil(target.relation) then
      target.relation = {}
   end

   if yIsNil(target.relation.affection) then
      target.relation.affection = 0
   end
   target.relation.affection = target.relation.affection + 1
   cur_dialogue["text"] = "you chat with " .. whos_names[target_i] ..
      "\n(current affection: " .. yeGetInt(target.relation.affection) .. ")";
end
