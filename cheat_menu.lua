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
   ywMenuPushSlider(menu.ent, "Chapter Select: ", slider)
   menu:push("Quests", Entity.new_func("cheat_quest_select_mn"))

   local money_action = Entity.new_array()
   money_action[0] = "phq.recive"
   money_action[1] = "money"
   money_action[2] = 50

   menu:push("give 50$", money_action)
   menu:push("NPCs", Entity.new_func("cheat_npcs_mn"))
   menu:push("Students", Entity.new_func("cheat_students_mn"))
   return menu.ent
end

function cheat_main_mn(mn)
   local cnt = ywCntWidgetFather(mn)
   ywReplaceEntry(cnt, 0, mk_main_mn())
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
   qmn.ent.onEsc = Entity.new_func("cheat_main_mn")
   qmn:push("Back", Entity.new_func("cheat_main_mn"))
   for i = 0, yeLen(phq.quests) - 1 do
      qmn:push(yeGetKeyAt(phq.quests, i), Entity.new_func("cheat_quest_action"))
   end
   qmn.ent.size = 30
   ywReplaceEntry(cnt, 0, qmn.ent)
   return YEVE_ACTION
end

function cheat_students_mn(main_mn)
   local cnt = ywCntWidgetFather(main_mn)
   local nmn = Menu.new_entity()

   nmn.ent["pre-text"] = "Quest Cheat Menu"
   nmn.ent.onEsc = Entity.new_func("cheat_main_mn")
   nmn:push("Back", Entity.new_func("cheat_main_mn"))
   for i = 0, yeLen(npcs) - 1 do
      local npc = yeGet(npcs, i)
      local npc_key = yeGetKeyAt(npcs, i)
      if yIsNNil(yeGet(npc, "student_year")) then
	 nmn:push(npc_key)
      end
   end
   nmn.ent.size = 30
   ywReplaceEntry(cnt, 0, nmn.ent)
   return YEVE_ACTION
end

function cheat_npcs_mn(main_mn)
   local cnt = ywCntWidgetFather(main_mn)
   local nmn = Menu.new_entity()

   nmn.ent["pre-text"] = "Quest Cheat Menu"
   nmn.ent.onEsc = Entity.new_func("cheat_main_mn")
   nmn:push("Back", Entity.new_func("cheat_main_mn"))
   for i = 0, yeLen(npcs) - 1 do
      local npc_key = yeGetKeyAt(npcs, i)

      if (yIsNNil(npc_key)) then
	 nmn:push(npc_key)
      end
   end
   nmn.ent.size = 30
   ywReplaceEntry(cnt, 0, nmn.ent)
   return YEVE_ACTION
end

function god_window(mn)
   local m = main_widget
   local ccw = Container.new_entity("vertical")
   ccw.ent.background = "rgba: 255 255 255 255"

   ccw.ent.entries[0] = mk_main_mn()
   ywPushNewWidget(m, ccw.ent)
   return YEVE_ACTION
end

