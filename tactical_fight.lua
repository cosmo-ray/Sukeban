MODE_NO_TACTICAL_FIGHT = 0
MODE_TACTICAL_FIGHT_INIT = 1
local MODE_PLAYER_TURN = 2

local BAR_H = 100
local bar_y = 0

TACTICAL_FIGHT_MODE = MODE_NO_TACTICAL_FIGHT

local function end_fight()
   local t = main_widget.tactical
   ywRemoveEntryByEntity(main_widget, t.screen)
   main_widget.tactical = nil
   TACTICAL_FIGHT_MODE = MODE_NO_TACTICAL_FIGHT
   
end

function do_tactical_fight(eve)
   local tdata = main_widget.tactical

   if TACTICAL_FIGHT_MODE == MODE_TACTICAL_FIGHT_INIT then
      printMessage(main_widget, nil,
		   "TACTICAL FIGHT MODE START, unimlemented press 'ESC' to quit")
      TACTICAL_FIGHT_MODE = MODE_PLAYER_TURN

      tdata.bads = {}
      tdata.goods = {}

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
      end

      print(wid_rect)
      local tatcical_can = Canvas.new_entity(tdata, "screen").ent
      local wid_rect = main_widget["wid-pix"]
      local wid_h = ywRectH(wid_rect)

      ywPushNewWidget(main_widget, tatcical_can)

      local sz = Size.new(ywRectW(wid_rect), BAR_H).ent
      --local sz = ywSizeCreate(100, 100)
      bar_y = wid_h - BAR_H - 10
      tdata.bar_background = ywCanvasNewRectangle(tatcical_can, 0, bar_y,
						  ywSizeW(sz), ywSizeH(sz),
						  "rgba: 0 0 0 200")
      tdata.bar_forground = ywCanvasNewRectangle(tatcical_can,
						 2, bar_y + 2,
						 ywSizeW(sz) - 4, ywSizeH(sz) - 4,
						 "rgba: 255 255 255 80")
      main_widget.current = 0
      print("c and txt: ", c, Entity.wrapp(bar_texture))
   end -- init out

   if yevIsKeyDown(eve, Y_ESC_KEY) then
      return end_fight()
   end

   reposeCam(main_widget)
   return YEVE_ACTION
end
