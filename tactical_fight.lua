MODE_NO_TACTICAL_FIGHT = 0
MODE_TACTICAL_FIGHT_INIT = 1
local MODE_PLAYER_TURN = 2

local PIX_MV_PER_MS = 5
local mouse_mv = 0
local pix_mouse_floor_left = 0

local BAR_H = 100
local bar_y = 0
local bar_x = 0

local HERO_TEAM = 0

TACTICAL_FIGHT_MODE = MODE_NO_TACTICAL_FIGHT

local current_character = 0

local function end_tun(tdata)
   tdata = Entity.wrapp(tdata)

   print("END TURN !!!!")
   current_character = current_character + 1
   current_character = current_character % yeLen(tdata.all)
end

local function end_fight()
   local t = main_widget.tactical
   ywRemoveEntryByEntity(main_widget, t.screen)
   main_widget.tactical = nil
   TACTICAL_FIGHT_MODE = MODE_NO_TACTICAL_FIGHT
   main_widget.cam_offset = nil
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

function push_character(tdata, dst, char, h, name, team)
   local i = yeLen(dst)
   dst[i] = {}
   dst[i][0] = char
   dst[i][1] = h
   dst[i][2] = name
   dst[i][3] = team
   yePushBack(tdata.all, dst[i])
end

function do_tactical_fight(eve)
   local tdata = main_widget.tactical
   local wid_rect = main_widget["wid-pix"]
   local wid_w = ywRectW(wid_rect)
   local wid_h = ywRectH(wid_rect)

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

      local pjPos = Pos.wrapp(ylpcsHandePos(main_widget.pj))
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

	 if k == "add-enemies" then
	    for j = 0, yeLen(a) - 1 do
	       npc = a[j]

	       local npcp = Pos.new(yeGetIntAt(npc, 0), yeGetIntAt(npc, 1))
	       local npcn = yeGetStringAt(npc, 2)
	       local npcd = lpcsStrToDir(yeGetStringAt(npc, 3))
	       local npc_desc = npcs[npcn]

	       if npc.is_generic then
		  npc_desc = Entity.new_copy(npc_desc)
	       end
	       local h = push_npc(npcp, npcn, npcd, npc_desc)

	       push_character(tdata, tdata.bads, npc_desc, h, npcn, 1)
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

      push_character(tdata, tdata.goods, phq.pj, main_widget.pj,
		     phq.pj.name, HERO_TEAM)
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
			npcn, HERO_TEAM)

      end
      yeShuffle(tdata.all)
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
      main_widget.current = 0

   end -- init out

   local all_char = tdata.all


   if TACTICAL_FIGHT_MODE == MODE_PLAYER_TURN then 
      if yevIsKeyDown(eve, Y_ESC_KEY) then
	 return end_fight()
      end
      local mx = yeveMouseX()
      local my = yeveMouseY()
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

      local buttons = tdata.buttons
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


   end -- player turn

   local turn_order_str = ""
   for i = 0, yeLen(all_char) -1 do
      local idx = (i + current_character) % yeLen(all_char)

      turn_order_str = turn_order_str .. yeGetString(all_char[idx][2]) .. "\n"
   end

   ywCanvasStringSet(tdata.turn_o_str, Entity.new_string(turn_order_str))

   reposeCam(main_widget)
   return YEVE_ACTION
end
