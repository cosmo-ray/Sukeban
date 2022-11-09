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

local function mk_main_mn()
   local menu = Menu.new_entity()
   menu.ent.size = 30
   menu.ent["pre-text"] = "Cheat Menu\nhere for debuging purpose:"
   menu.ent.onEsc = Entity.new_func("popGlobMnOtherMenu")
   menu:push("back", Entity.new_func("popGlobMnOtherMenu"))
   local slider = Entity.new_array()
   slider[0] = {}
   slider[0].text = "night"
   slider[0].action = {"recreateString", "phq.env.time", "night"}
   slider[1] = {}
   slider[1].text = "day"
   slider[1].action = {"recreateString", "phq.env.time", "day"}
   slider[2] = {}
   slider[2].text = "morning"
   slider[2].action = {"recreateString", "phq.env.time", "morning"}
   ywMenuPushSlider(menu.ent, "Time Select: ", slider)
   slider = Entity.new_array()
   slider[0] = {}
   slider[0].text = "prolgue"
   slider[0].action = {"recreateInt", "phq.env.chapter", 0}
   slider[1] = {}
   slider[1].text = "1"
   slider[1].actions = {}
   slider[1].actions[0] = {"recreateInt", "phq.env.day", 1}
   slider[1].actions[1] = {"recreateString", "phq.env.time", "night"}
   slider[1].actions[2] = {"phq:quest_script", "end_chapter_0"}
   slider[1].actions[3] = Entity.new_func(popGlobMnOtherMenu)
   ywMenuPushSlider(menu.ent, "Chapter Select: ", slider)
   menu:push("Quests", Entity.new_func(cheat_quest_select_mn))

   local money_action = Entity.new_array()
   money_action[0] = "phq.recive"
   money_action[1] = "money"
   money_action[2] = 50

   menu:push("give 50$", money_action)

   local xp_action = Entity.new_array()
   xp_action[0] = "phq.increase"
   xp_action[1] = "xp"
   xp_action[2] = 50
   menu:push("give 50 xp", xp_action)

   local m_actions = Entity.new_array()
   m_actions[0] = {"phq.openGlobMenu", 3}

   local e = menu:push("Metro")
   e.actions = m_actions
   menu:push("NPCs", Entity.new_func(cheat_npcs_mn))
   menu:push("Students", Entity.new_func(cheat_students_mn))

   menu.ent.in_subcontained = 1
   return menu.ent
end

function cheat_main_mn(mn)
   local cnt = ywCntWidgetFather(mn)
   ywReplaceEntry(cnt, 0, mk_main_mn())
   Entity.wrapp(cnt).in_subcontained = 1
   return YEVE_ACTION
end

function cheat_quest_action(mn)
   local cur_txt = Entity.wrapp(ywMenuGetCurrentEntry(mn)).text:to_string()
   print(cur_txt, phq.quests[cur_txt], "phq.quests." .. cur_txt)
   ygIncreaseInt("phq.quests." .. cur_txt, 1);
   print(cur_txt, phq.quests[cur_txt], "phq.quests." .. cur_txt)
   local f = ywCntWidgetFather(mn)
   popGlobMnOtherMenu(mn)
   return backToGame(f)
end

function cheat_quest_select_mn(main_mn)
   local cnt = ywCntWidgetFather(main_mn)
   local qmn = Menu.new_entity()

   qmn.ent["pre-text"] = "Quest Cheat Menu"
   qmn.ent.onEsc = Entity.new_func(cheat_main_mn)
   qmn:push("Back", Entity.new_func(cheat_main_mn))
   for i = 0, yeLen(phq.quests) - 1 do
      qmn:push(yeGetKeyAt(phq.quests, i), Entity.new_func(cheat_quest_action))
   end
   qmn.ent.size = 30
   ywReplaceEntry(cnt, 0, qmn.ent)
   return YEVE_ACTION
end

function cheat_students_mn(main_mn)
   local cnt = Entity.wrapp(ywCntWidgetFather(main_mn))
   local nmn = Menu.new_entity()

   nmn.ent["pre-text"] = "Quest Cheat Menu"
   nmn.ent.onEsc = Entity.new_func(cheat_main_mn)
   nmn.ent.moveOn = Entity.new_func(cheat_show_npc)
   nmn:push("Back", Entity.new_func(cheat_main_mn))
   for i = 0, yeLen(npcs) - 1 do
      local npc = yeGet(npcs, i)
      local npc_key = yeGetKeyAt(npcs, i)
      if yIsNNil(yeGet(npc, "student_year")) then
	 nmn:push(npc_key)
      end
   end
   nmn.ent.size = 30
   ywReplaceEntry(cnt, 0, nmn.ent)
   ywPushNewWidget(cnt, Canvas.new_entity().ent);
   cnt.current = 0
   return YEVE_ACTION
end

function cheat_show_npc(mn, _current)
   local cur = Entity.wrapp(ywMenuGetCurrentEntry(mn))
   local cnt = ywCntWidgetFather(mn)
   local canvas = Entity.wrapp(ywCntGetEntry(cnt, 1))
   local npc = npcs[cur.text]
   local handler

   canvas.h = nil
   ywCanvasClear(canvas)
   if yIsNil(npc) then
      return YEVE_ACTION;
   end
   if yeGetString(npc.type) == "sprite" then
      canvas.h = sprite_man.createHandler(npc, canvas)
   else
      dressup.dressUp(npc)
      canvas.h = lpcs.createCaracterHandler(npc, canvas)
      canvas.h.y = LPCS_DOWN
   end
   handler = canvas.h
   generic_handlerRefresh(handler)

   yShowDialogueImage(canvas, npc)
   if npc.stats then
      ywCanvasNewTextExt(canvas, 200, 20,
			 Entity.new_string(npc.stats:to_string()),
			 "rgba: 0 0 0 255")
   end
   if npc.trait then
      ywCanvasNewTextExt(canvas, 200, 120,
			 Entity.new_string(npc.trait:to_string()),
			 "rgba: 0 0 0 255")
   end
   return YEVE_ACTION;
end

function cheat_npcs_mn(main_mn)
   local cnt = Entity.wrapp(ywCntWidgetFather(main_mn))
   local nmn = Menu.new_entity()

   nmn.ent["pre-text"] = "Quest Cheat Menu"

   nmn.ent.moveOn = Entity.new_func(cheat_show_npc)
   nmn:push("Back", Entity.new_func(cheat_main_mn))
   nmn.ent.onEsc = Entity.new_func(cheat_main_mn)

   for i = 0, yeLen(npcs) - 1 do
      local npc_key = yeGetKeyAt(npcs, i)

      if (yIsNNil(npc_key)) then
	 nmn:push(npc_key)
      end
   end
   nmn.ent.size = 30
   ywReplaceEntry(cnt, 0, nmn.ent)
   ywPushNewWidget(cnt, Canvas.new_entity().ent);
   cnt.current = 0
   return YEVE_ACTION
end

function god_window(_mn)
   local m = main_widget
   local ccw = Container.new_entity("vertical")
   ccw.ent.background = "rgba: 255 255 255 255"

   ccw.ent.entries[0] = mk_main_mn()
   ywPushNewWidget(m, ccw.ent)
   return YEVE_ACTION
end

