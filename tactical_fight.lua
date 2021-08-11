MODE_NO_TACTICAL_FIGHT = 0
MODE_TACTICAL_FIGHT_INIT = 1
local MODE_PLAYER_TURN = 2

local PIX_MV_PER_MS = 5
local mouse_mv = 0
local pix_mouse_floor_left = 0

local BAR_H = 100
local bar_y = 0

local HERO_TEAM = 0

TACTICAL_FIGHT_MODE = MODE_NO_TACTICAL_FIGHT

local function end_fight()
   local t = main_widget.tactical
   ywRemoveEntryByEntity(main_widget, t.screen)
   main_widget.tactical = nil
   TACTICAL_FIGHT_MODE = MODE_NO_TACTICAL_FIGHT
   main_widget.cam_offset = nil
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

	       tdata.bads[j] = {}
	       tdata.bads[j][0] = npc_desc
	       tdata.bads[j][1] = h
	       tdata.bads[j][2] = npcn
	       tdata.bads[j][3] = 1
	       yePushBack(tdata.all, tdata.bads[j])
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

      tdata.goods[0] = {}
      tdata.goods[0][0] = phq.pj
      tdata.goods[0][1] = main_widget.pj
      tdata.goods[0][2] = phq.pj.name
      tdata.goods[0][3] = HERO_TEAM
      yePushBack(tdata.all, tdata.goods[0])

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

	 tdata.goods[i] = {}
	 tdata.goods[i][0] = npc
	 tdata.goods[i][1] = push_npc(npcp, npcn, main_widget.pj.y:to_int(),
				      npc)
	 tdata.goods[i][2] = npcn
	 tdata.goods[i][3] = HERO_TEAM
	 yePushBack(tdata.all, tdata.goods[i])

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
      main_widget.current = 0
   end -- init out

   local all_char = tdata.all
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

   local turn_order_str = ""
   for i = 0, yeLen(all_char) -1 do
      turn_order_str = turn_order_str .. yeGetString(all_char[i][2]) .. "\n"
   end

   ywCanvasStringSet(tdata.turn_o_str, Entity.new_string(turn_order_str))
   reposeCam(main_widget)
   return YEVE_ACTION
end
