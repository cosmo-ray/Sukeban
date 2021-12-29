MODE_NO_TACTICAL_FIGHT = 0
MODE_TACTICAL_FIGHT_INIT = 1
local MODE_PLAYER_TURN = 2
local MODE_ENEMY_TURN = 3
local MODE_CHAR_MOVE = 4
local MODE_CHAR_ATTACK = 5

local PIX_MV_PER_MS = 5
local mouse_mv = 0
local pix_mouse_floor_left = 0

local BAR_H = 100
local bar_y = 0
local bar_x = 0

local HERO_TEAM = 0

TACTICAL_FIGHT_MODE = MODE_NO_TACTICAL_FIGHT
EX_MODE = 0

local current_character = 0

local IDX_MAX_ACTION_POINT = 0
local IDX_CUR_ACTION_POINT = 1
local IDX_PIX_MV = 2
local IDX_NPC_DIR = 3

local IDX_TMP_DATA = 8
local IDX_TIMER = 9
local IDX_AI_STUFF = 10

local TC_IXD_CHAR = 0
local TC_IDX_HDLR = 1
local TC_IDX_NAME = 2
local TC_IDX_TEAM = 3
local TC_IDX_TDTA = 4

local cur_char = nil

local move_dst = nil
local atk_target = nil

local block_square = nil

local COL_FAR_ALLY = "rgba: 100 155 100 130"
local COL_NEAR_ALLY = "rgba: 55 255 50 130"
local COL_FAR_ENEMY = "rgba: 155 100 100 130"
local COL_NEAR_ENEMY = "rgba: 255 105 50 130"

local pix_floor_left = 0

local function begin_turn_init(tdata)
   cur_char = tdata.all[current_character]
   cur_char[TC_IDX_TDTA][IDX_CUR_ACTION_POINT] =
      Entity.new_float(cur_char[TC_IDX_TDTA][IDX_MAX_ACTION_POINT]:to_int())
   if yeGetInt(cur_char[TC_IDX_TEAM]) == HERO_TEAM then
      TACTICAL_FIGHT_MODE = MODE_PLAYER_TURN
   else
      TACTICAL_FIGHT_MODE = MODE_ENEMY_TURN
   end
end

local function repush_idx(all)
   for i = 0, yeLen(all) - 1 do
      local h = all[i][1]
      h.canvas.idx = i
   end
end

local function end_tun(tdata)
   tdata = Entity.wrapp(tdata)

   print("END TURN !!!!")
   current_character = current_character + 1
   current_character = current_character % yeLen(tdata.all)
   repush_idx(tdata.all)
   begin_turn_init(tdata)
   ywCanvasStringSet(tdata.movement_info, Entity.new_string(""))
end

local function center_char(tdata)
   print("click center !!!")
   main_widget.cam_offset = Pos.new(0, BAR_H / 2).ent
end

-- take a canvas pos and translate it to real char pos
local function canvas_to_char_pos(cpos)
   local char_pos = Entity.new_copy(cpos)
   local char_size = generic_handlerSize(cur_char[1])
   ywPosAddXY(char_pos, ywSizeW(char_size) / 2, ywSizeH(char_size) / 3 * 2)
   return char_pos
end

local function char_to_canvas_pos(cpos)
   local can_pos = Entity.new_copy(cpos)
   local can_size = generic_handlerSize(cur_char[1])
   ywPosAddXY(can_pos, -(ywSizeW(can_size) / 2), -(ywSizeH(can_size) / 3 * 2))
   return can_pos
end

local function tchar_ch_pos(tchar)
   return canvas_to_char_pos(generic_handlerPos(tchar[TC_IDX_HDLR]))
end

local function tchar_can_pos(tchar)
   return Entity.new_copy(generic_handlerPos(tchar[TC_IDX_HDLR]))
end

local function tchar_can_pos_x(tchar)
   return ywPosX(generic_handlerPos(tchar[TC_IDX_HDLR]))
end

local function tchar_can_pos_y(tchar)
   return ywPosY(generic_handlerPos(tchar[TC_IDX_HDLR]))
end

local function end_fight()
   local main_canvas = main_widget.mainScreen
   local t = main_widget.tactical
   ywCanvasRemoveObj(main_canvas, t.cur_ch_square)
   ywRemoveEntryByEntity(main_widget, t.screen)
   TACTICAL_FIGHT_MODE = MODE_NO_TACTICAL_FIGHT
   main_widget.cam_offset = nil
   move_dst = nil
   cur_char = nil
   atk_target = nil
   if phq_only_fight > 0 then
      fight_mode_wid()
   end
   if yIsNNil(t.bak_npcs) then
      local npcs = t.bak_npcs
      main_widget.npcs = npcs
      for i = 0, yeLen(npcs) - 1 do
	 generic_handlerRefresh(npcs[i])
	 restoreNpcCanvasMatadata(npcs[i].canvas, npcs[i].mdt_bak)
	 npcs[i].mdt_bak = nil
      end
   end

   main_widget.tactical = nil
end

local function push_button(tdata, rect, txt, callback)
   local tatcical_can = tdata.screen
   local b = Entity.new_array(tdata.buttons)
   ywPosAdd(rect, bar_x, bar_y)
   b[0] = rect
   b[1] = callback
   b[2] = ywCanvasNewRectangle(tatcical_can, ywRectX(rect), ywRectY(rect),
			       ywRectW(rect), ywRectH(rect), "rgba: 0 255 0 200")
   b[3] = ywCanvasNewTextByStr(tatcical_can, ywRectX(rect), ywRectY(rect), txt)
end

local function highlight_button(tdata, b)
   if yIsNil(b[4]) then
      local rect = b[0]

      b[4] = ywCanvasNewRectangle(tdata.screen, ywRectX(rect) + 2,
				  ywRectY(rect) + 2,
				  ywRectW(rect) - 4, ywRectH(rect) - 4,
				  "rgba: 0 0 0 100")
   end
end

local function unlight_button(tdata, b)
   if yIsNNil(b[4]) then
      ywCanvasRemoveObj(tdata.screen, b[4])
      b[4] = nil
   end
end

local function push_character(tdata, dst, char, h, name, team, dir)
   -- recenter char
   local s = generic_handlerSize(h)
   generic_handlerMoveXY(h, -(ywSizeW(s) / 2), -(ywSizeH(s) / 3 * 2))

   if yIsNil(char.life) then
      char.life = yeGetInt(char.max_life)
   end

   local i = yeLen(dst)
   dst[i] = {}
   dst[i][TC_IXD_CHAR] = char
   dst[i][TC_IDX_HDLR] = h
   dst[i][TC_IDX_NAME] = name
   dst[i][TC_IDX_TEAM] = team
   dst[i][TC_IDX_TDTA] = {}
   local tactical_info = dst[i][TC_IDX_TDTA]
   tactical_info[IDX_MAX_ACTION_POINT] = 5
   tactical_info[IDX_PIX_MV] = 0
   tactical_info[IDX_NPC_DIR] = dir
   local tdata_all = tdata.all
   h.canvas.idx = yeLen(tdata_all)
   yePushBack(tdata_all, dst[i])
end

local function bad_guy_end_turn(cur_char_t, tdata)
   	 cur_char_t[IDX_AI_STUFF] = nil
	 end_tun(tdata)
end


local function remove_character(tdata, target)
   print("remove: ", target[TC_IDX_NAME], yeLen(tdata.all))
   generic_handlerNullify(target[1])
   yeEraseByE(tdata.all, target)
   print("af rm: ", yeLen(tdata.all))
   yeEraseByE(tdata.bads, target)
   repush_idx(tdata.all)
end

local function switch_to_move_mode(dst, ap_cost)
   EX_MODE = TACTICAL_FIGHT_MODE
   TACTICAL_FIGHT_MODE = MODE_CHAR_MOVE
   local ap = yeGetFloat(cur_char[TC_IDX_TDTA][IDX_CUR_ACTION_POINT])
   yeSetFloat(cur_char[TC_IDX_TDTA][IDX_CUR_ACTION_POINT], ap - ap_cost)
   move_dst = dst
end

local function switch_to_attack_mode(target, ap_cost)
   EX_MODE = TACTICAL_FIGHT_MODE
   TACTICAL_FIGHT_MODE = MODE_CHAR_ATTACK
   local ap = yeGetFloat(cur_char[TC_IDX_TDTA][IDX_CUR_ACTION_POINT])
   yeSetFloat(cur_char[TC_IDX_TDTA][IDX_CUR_ACTION_POINT], ap - ap_cost)
   atk_target = target
end

function do_tactical_fight(eve)
   local tdata = main_widget.tactical
   local wid_rect = main_widget["wid-pix"]
   local wid_w = ywRectW(wid_rect)
   local wid_h = ywRectH(wid_rect)
   local main_canvas = main_widget.mainScreen
   local ccam = main_canvas.cam

   -- get weapon stats here
   local reach_distance = 80
   local attack_strengh = 5
   local attack_cost = 1

   if block_square then
      ywCanvasRemoveObj(main_canvas, block_square)
      block_square = nil
   end
   if TACTICAL_FIGHT_MODE == MODE_TACTICAL_FIGHT_INIT then
      main_widget.cam_offset = Pos.new(0, BAR_H / 2).ent
      printMessage(main_widget, nil,
		   "TACTICAL FIGHT MODE START, unimlemented press 'ESC' to quit")
      TACTICAL_FIGHT_MODE = MODE_PLAYER_TURN

      tdata.bads = {}
      tdata.goods = {}
      tdata.all = {}
      tdata.buttons = {}
      current_character = 0

      local args = tdata.args
      local tmp_allies = {}
      local tmp_allies_idx = 1
      local allies = phq.pj.allies

      for i = 0, yeLen(allies) - 1 do
	 tmp_allies[tmp_allies_idx] = yeGetKeyAt(allies, i)
	 tmp_allies_idx = tmp_allies_idx + 1
      end
      for i = 0, yeLen(args) - 1 do
	 local k = yeGetKeyAt(args, i)
	 local a = args[i]

	 if k == "backup-npc" then
	    local npcs = main_widget.npcs
	    tdata.bak_npcs = npcs
	    for i = 0, yeLen(npcs) - 1 do
	       saveNpcCanvasMatadata(npcs[i].canvas, npcs[i].mdt_bak)
	       generic_handlerRmCanva(npcs[i])
	    end
	    main_widget.npcs = {}
	 elseif k == "move" then
	    for j = 0, yeLen(a) - 1 do
	       local name = ylaCreateYirlFmtString(a[j][0])
	       print("move: ", a[j], yeGetString(name),
		     yeGetString(name) == yeGetString(phq.pj.name))
	       if yeGetString(name) == yeGetString(phq.pj.name) then
		  generic_handlerMoveXY(main_widget.pj,
					yeGetInt(a[j][1]),
					yeGetInt(a[j][2]))
	       else
		  local goods = tdata.goods
		  for k = 0, yeLen(goods) - 1 do
		     if yeGetString(name) == yeGetString(goods[2]) then
			generic_handlerMoveXY(goods[1],
					      yeGetInt(a[j][1]),
					      yeGetInt(a[j][2]))
		     end
		  end
	       end
	    end
	 elseif k == "add-enemies" then
	    for j = 0, yeLen(a) - 1 do
	       npc = a[j]

	       local npcp = Pos.new(yeGetIntAt(npc, 0), yeGetIntAt(npc, 1))
	       local npcn = yeGetStringAt(npc, 2)
	       local npcd = lpcsStrToDir(yeGetStringAt(npc, 3))
	       local npc_desc = npcs[npcn]

	       if npc_desc.is_generic then
		  npc_desc = Entity.new_copy(npc_desc)
	       end
	       local h = push_npc(npcp, npcn, npcd, npc_desc)
	       push_character(tdata, tdata.bads, npc_desc, h, npcn, 1, npcd)
	    end
	 elseif k == "add-ally" then
	    for j = 0, yeLen(a) - 1 do
	       npc = a[j]

	       local npcn = yeGetStringAt(npc, 0)

	       tmp_allies[tmp_allies_idx] = npcn
	       tmp_allies_idx = tmp_allies_idx + 1
	    end
	 end
      end
      local pjPos = Pos.wrapp(Entity.new_copy(ylpcsHandePos(main_widget.pj)))
      local pj_dir = main_widget.pj.y:to_int()

      push_character(tdata, tdata.goods, phq.pj, main_widget.pj,
		     phq.pj.name, HERO_TEAM, pj_dir)
      for i = 1, #tmp_allies do

	 local npcn = tmp_allies[i]
	 local npc = npcs[npcn]
	 if npc.is_generic then
	    npc = Entity.new_copy(npc)
	 end

	 local px = pjPos:x()
	 local py = pjPos:y()
	 if (i - 1) % 2 == 0 then
	    px = px - (i / 2 + 1) * 60 - 20
	 else
	    px = px + (i / 2 + 1) * 60
	 end
	 local npcp = Pos.new(px, py)

	 push_character(tdata, tdata.goods, npc,
			push_npc(npcp, npcn, main_widget.pj.y:to_int(), npc),
			npcn, HERO_TEAM, pj_dir)

      end
      yeShuffle(tdata.all)
      repush_idx(tdata.all)
      local tatcical_can = Canvas.new_entity(tdata, "screen").ent

      ywPushNewWidget(main_widget, tatcical_can)

      local sz = Size.new(wid_w, BAR_H).ent
      --local sz = ywSizeCreate(100, 100)
      bar_y = wid_h - BAR_H - 10
      tdata.ibar_background = ywCanvasNewRectangle(tatcical_can, 0, bar_y,
						  ywSizeW(sz), ywSizeH(sz),
						  "rgba: 0 0 0 200")
      tdata.ibar_forground = ywCanvasNewRectangle(tatcical_can,
						 2, bar_y + 2,
						 ywSizeW(sz) - 4, ywSizeH(sz) - 4,
						 "rgba: 255 255 255 80")

      tdata.turn_o_str = ywCanvasNewTextByStr(tdata.screen, wid_w - 100, 10, "")
      push_button(tdata, Rect.new(ywSizeW(sz) - 160, 4, 100, 30).ent,
		  "end turn", Entity.new_func(end_tun))
      push_button(tdata, Rect.new(ywSizeW(sz) - 160, 36, 100, 30).ent,
		  "center", Entity.new_func(center_char))
      tdata.ap_info = ywCanvasNewTextByStr(tdata.screen, bar_x + 10,
					   bar_y + 10, "")
      tdata.movement_info = ywCanvasNewTextByStr(tdata.screen, 0,
					   o, "")

      main_widget.current = 0

      tdata.cur_ch_square = ywCanvasNewRectangle(main_canvas, 0, 0, 32, 32,
						 "rgba: 127 127 127 120")

      begin_turn_init(tdata)
   end -- init out

   local all_char = tdata.all
   local cur_char_t = cur_char[TC_IDX_TDTA]
   local ap = yeGetFloat(cur_char_t[IDX_CUR_ACTION_POINT])

   if TACTICAL_FIGHT_MODE == MODE_PLAYER_TURN then 
      if yevIsKeyDown(eve, Y_ESC_KEY) then
	 return end_fight()
      end
      local mx = yeveMouseX()
      local my = yeveMouseY()
      local bar_rect = Rect.new(bar_x, bar_y, wid_w, BAR_H).ent
      local turn_timer = ywidTurnTimer() / 10000

      mouse_mv = turn_timer * PIX_MV_PER_MS + pix_mouse_floor_left
      pix_mouse_floor_left = mouse_mv - math.floor(mouse_mv)

      if mx > wid_w - 5 then
	 yeAddAt(main_widget.cam_offset, 0, mouse_mv)
      elseif mx < 5 then
	 yeAddAt(main_widget.cam_offset, 0, -mouse_mv)
      end
      if my > wid_h - 5 then
	 yeAddAt(main_widget.cam_offset, 1, mouse_mv)
      elseif my < 5 then
	 yeAddAt(main_widget.cam_offset, 1, -mouse_mv)
      end

      if (ywRectContain(bar_rect, mx, my, 0) > 0) then
	 local buttons = tdata.buttons
	 ywCanvasStringSet(tdata.movement_info, Entity.new_string(""))
	 for i = 0, yeLen(buttons) - 1 do
	    local b = buttons[i]
	    local isOver = ywRectContain(b[0], mx, my, 1) > 0
	    if isOver then
	       highlight_button(tdata, b)
	       if yevMouseDown(eve) then
		  if yIsNNil(b[1]) then
		     b[1](tdata)
		  end
	       end
	    else
	       unlight_button(tdata, b)
	    end
	 end
      else -- on game map
	 local mv_info = tdata.movement_info
	 local mouse_real_pos = Pos.new(mx, my).ent
	 ywPosAdd(mouse_real_pos, ccam)
	 -- ylpcsHandlerPos return top left, we need center
	 local char_pos = tchar_ch_pos(cur_char)
	 local dist_ap_cost = (ywPosDistance(char_pos, mouse_real_pos)  / 100)
	 local mov_cost = "(" .. dist_ap_cost .. ")"

	 local block = (dist_ap_cost > ap)
	 local cur_char_canva = cur_char[1].canvas
	 local nearest_target = nil
	 local target_distance = 0

	 if block == false then
	    local intersect_array = ylaCanvasIntersectArray(main_canvas,
							    char_pos,
							    mouse_real_pos)
	    for i = 0, yeLen(intersect_array) - 1 do
	       local col_o = yeGet(intersect_array, i)

	       if yeGetIntAt(col_o, 9) < 1 or
		  cur_char_canva == Entity.wrapp(col_o) then
		  goto loop_next
	       end

	       col_o = Entity.wrapp(col_o)
	       if yIsNil(col_o.idx) then
		  block = true
		  goto loop_next
	       end
	       local col_char = tdata.all[yeGetInt(col_o.idx)]

	       if nearest_target == nil then
		  local p = tchar_ch_pos(col_char)
		  nearest_target = col_char
		  target_distance = ywPosDistance(char_pos, p)
	       else
		  local p0 = tchar_ch_pos(nearest_target)
		  local p1 = tchar_ch_pos(col_char)
		  local d0 = ywPosDistance(char_pos, p0)
		  local d1 = ywPosDistance(char_pos, p1)
		  
		  if d0 > d1 then
		     nearest_target = col_char
		     target_distance = d1
		  end
	       end

	       block = true
	       :: loop_next ::
	    end

	    if nearest_target then
	       local p = generic_handlerPos(nearest_target[1])
	       local s = generic_handlerSize(nearest_target[1])
	       local col = nil

	       if yeGetInt(nearest_target[TC_IDX_TEAM]) == HERO_TEAM then
		  if target_distance < reach_distance then
		     col = COL_NEAR_ALLY
		  else
		     col = COL_FAR_ALLY
		  end
	       else
		  if target_distance < reach_distance then
		     col = COL_NEAR_ENEMY
		  else
		     col = COL_FAR_ENEMY
		  end
	       end
	       block_square = ywCanvasNewRectangle(main_canvas,
						   ywPosX(p) + 4,
						   ywPosY(p) + ywSizeH(s) - 32,
						   32, 32, col)
	    end
	 end

	 ywCanvasStringSet(mv_info, Entity.new_string(mov_cost))
	 ywCanvasObjSetPos(mv_info, mx, my)
	 if block then
	    ywCanvasSetStrColor(mv_info, "rgba: 230 20 20 255")
	 else
	    ywCanvasSetStrColor(mv_info, "rgba: 255 255 255 255")
	 end
	 if yevMouseDown(eve) then
	    print("click !")
	    if block then
	       if nearest_target then
		  if target_distance >= reach_distance then
		     printMessage(main_widget, nil,
				  "target is out of reac (distance: " .. target_distance .. ") !")
		  elseif nearest_target[TC_IDX_TEAM]:to_int() == HERO_TEAM then
		     printMessage(main_widget, nil, "can't attack allies")
		  else
		     printMessage(main_widget, nil,
				  cur_char[TC_IDX_NAME]:to_string() ..
				  " attack: " ..
				  nearest_target[TC_IDX_NAME]:to_string())
		     switch_to_attack_mode(nearest_target, attack_cost)
		  end
		  print("attack on", nearest_target[TC_IDX_NAME])
	       end
	       print("block")
	    else
	       switch_to_move_mode(char_to_canvas_pos(mouse_real_pos),
				   dist_ap_cost)
	    end
	 end
      end

   elseif TACTICAL_FIGHT_MODE == MODE_ENEMY_TURN then

      if cur_char_t[IDX_MAX_ACTION_POINT] < 0.12 then
	 bad_guy_end_turn(cur_char_t, tdata)
      end

      if yIsNil(cur_char_t[IDX_AI_STUFF]) then
	 cur_char_t[IDX_AI_STUFF] = {}
	 cur_char_t[IDX_AI_STUFF].timer = 0
      end
      local ai_stuff = cur_char_t[IDX_AI_STUFF]
      local target = nil
      print("ai cur_char_t:", cur_char_t)
      local goods = tdata.goods
      local cur_ch = cur_char[TC_IXD_CHAR]
      local o_ch = goods[TC_IXD_CHAR]
      local target_dist = 4000
      local target_pos = nil
      local cpos = tchar_ch_pos(cur_char)

      for i = 0, yeLen(goods) - 1 do
	 local cc = cpos
	 local oc = tchar_ch_pos(goods[i])
	 local dist = ywPosDistance(cc, oc)
	 local intersect_array = ylaCanvasIntersectArray(main_canvas, cc, oc)
	 local block = false

	 for j = 0, yeLen(intersect_array) - 1 do
	    local col_o = Entity.wrapp(yeGet(intersect_array, i))

	    if yeGetIntAt(col_o, 9) < 1 or
	       cur_ch == col_o or
	       o_ch == col_o
	    then
	       goto _continue_
	    end

	    block = true
	    break
	    :: _continue_ ::
	 end -- for inersect

	 if block == false and dist < target_dist then
	    target = goods[i]
	    target_dist = dist
	    local tpos = oc
	    local distance = dist
	    print("dist, distance: ", dist, distance, target_dist)
	    local xdist = ywPosXDistance(cpos, tpos)
	    local ydist = ywPosYDistance(cpos, tpos)
	    targeted_pos = Entity.new_copy(tpos)
	    ywPosAddXY(targeted_pos,
		       -(reach_distance * xdist / distance),
		       -(reach_distance * ydist / distance))
	    print("TARGET:\n",
		  tpos,
		  cpos,
		  tchar_ch_pos(target),
		  tchar_ch_pos(cur_char),
		  "\ndistances:\n", distance, xdist, ydist,
		  "\nreach distances in:\n",
		  reach_distance,
		  "\nreach distances out:\n",
		  (reach_distance * xdist / distance),
		  (reach_distance * ydist / distance),
		  "\ntargeted pos:\n", targeted_pos
	    )
	 end -- if target

      end -- for goods

      if targeted_pos == nil then
	 print("NO TARGET !")
      else
	 if target_dist > reach_distance then
	    local dist_ap_cost = (ywPosDistance(cpos, targeted_pos)  / 100)

	    switch_to_move_mode(char_to_canvas_pos(targeted_pos), dist_ap_cost)
	    print("SWITCH MOVE MODE")
	 else
	    print("CAN ATTACK: ", target[TC_IDX_NAME])
	 end
      end -- target_pos not nil

      ai_stuff.timer = ai_stuff.timer + 1

      if ai_stuff.timer > 10 then
	 bad_guy_end_turn(cur_char_t, tdata)
      end
   elseif TACTICAL_FIGHT_MODE == MODE_CHAR_MOVE then
      local char_pos = generic_handlerPos(cur_char[1])
      local PIX_MV_PER_MS = 5
      local turn_timer = ywidTurnTimer() / 10000
      local pix_mv = turn_timer * PIX_MV_PER_MS + pix_floor_left
      pix_floor_left = pix_mv - math.floor(pix_mv)
      cur_char[TC_IDX_TDTA][IDX_PIX_MV] = cur_char[TC_IDX_TDTA][IDX_PIX_MV] + pix_mv
      local x_tot_dist = ywPosXDistance(char_pos, move_dst)
      local y_tot_dist = ywPosYDistance(char_pos, move_dst)
      local tot_dist = math.sqrt(x_tot_dist * x_tot_dist + y_tot_dist * y_tot_dist)
      local x_mv = x_tot_dist * pix_mv / tot_dist
      local y_mv = y_tot_dist * pix_mv / tot_dist

      print(pix_mv, tot_dist)
      print(x_tot_dist, y_tot_dist, "\n",
	    x_mv,
	    y_mv)
      --local mvPos = Pos.new(pix_mv * ),
      --pix_mv * )
      if (math.abs(tot_dist) < 30) then
	 generic_setPos(cur_char[1], move_dst)
	 TACTICAL_FIGHT_MODE = EX_MODE
      else
	 generic_handlerMoveXY(cur_char[1], x_mv, y_mv)
      end

      local aimed_dir = distanceToDir(x_mv, y_mv)
      if yeGetInt(cur_char[TC_IDX_TDTA][IDX_NPC_DIR]) ~= aimed_dir then
	 generic_setDir(cur_char[1], aimed_dir)
	 cur_char[TC_IDX_TDTA][IDX_NPC_DIR] = aimed_dir
      end

      if cur_char[TC_IDX_TDTA][IDX_PIX_MV] > 20 then

	 if yeGetString(cur_char[1].char.type) ~= "sprite" then
	    ylpcsHandlerNextStep(cur_char[1])
	 end

	 generic_handlerRefresh(cur_char[1])
	 cur_char[TC_IDX_TDTA][IDX_PIX_MV] = 0
      end

   elseif TACTICAL_FIGHT_MODE == MODE_CHAR_ATTACK then
      if yIsNil(cur_char_t[IDX_TIMER]) then
	 cur_char_t[IDX_TIMER] = 1
	 printMessage(main_widget, nil,
		      yeGetString(atk_target[TC_IDX_NAME]) .. " take " ..
		      attack_strengh .. " damages")

	 atk_target[TC_IXD_CHAR].life = atk_target[TC_IXD_CHAR].life -
	    attack_strengh

	 cur_char_t[IDX_TMP_DATA] = ywCanvasNewImgByPath(main_widget.upCanvas,
							 tchar_can_pos_x(atk_target),
							 tchar_can_pos_y(atk_target),
							 "imgs/explosion.png")
      elseif cur_char_t[IDX_TIMER] < 10 then
	 cur_char_t[IDX_TIMER] = cur_char_t[IDX_TIMER] + ywidTurnTimer() / 10000
      else
	 if atk_target[TC_IXD_CHAR].life < 1 then
	    print("He's DEAD !")
	    remove_character(tdata, atk_target)
	    atk_target = nil
	 end
	 ywCanvasRemoveObj(main_widget.upCanvas, cur_char_t[IDX_TMP_DATA])
	 TACTICAL_FIGHT_MODE = EX_MODE
	 cur_char_t[IDX_TIMER] = nil
      end
   end

   -- print all stuf
   local cur_ch_pos = generic_handlerPos(cur_char[1])
   local cur_ch_size = generic_handlerSize(cur_char[1])
   ywCanvasObjSetPos(tdata.cur_ch_square, ywPosX(cur_ch_pos) + 4,
		     ywPosY(cur_ch_pos) + ywSizeH(cur_ch_size) - 32)

   ywCanvasObjSetPos(mv_info, mx, my)
   local turn_order_str = ""
   for i = 0, yeLen(all_char) -1 do
      local idx = (i + current_character) % yeLen(all_char)

      turn_order_str = turn_order_str ..
	 yeGetString(all_char[idx][TC_IDX_NAME]) .. "\n"
   end

   ywCanvasStringSet(tdata.turn_o_str, Entity.new_string(turn_order_str))

   local ap_str = "Action Points: ["
   local max_ap = cur_char_t[IDX_MAX_ACTION_POINT]
   for i = 0, yeGetInt(max_ap) - 1 do
      if i < ap and ap - i < 0.12 then
	 ap_str = ap_str .. " "	 
      elseif i < ap and ap - i < 1 then
	 ap_str = ap_str .. "o"	 
      elseif i < ap then
	 ap_str = ap_str .. "O"
      else
	 ap_str = ap_str .. " "
      end
   end
   ap_str = ap_str .. "]"
   ywCanvasStringSet(tdata.ap_info, Entity.new_string(ap_str))

   reposeCam(main_widget, cur_char[1])
   return YEVE_ACTION
end
