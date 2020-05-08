local phq = Entity.wrapp(ygGet("phq"))

local function mk_main_mn()
   local menu = Menu.new_entity()
   menu.ent.size = 30
   menu.ent["pre-text"] = "Cheat Menu\nhere for debuging purpose:"
   menu:push("back", Entity.new_func("popSpendXpWid"))
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
   slider[1].actions[0] = {"recreateInt", "phq.env.chapter", 1}
   slider[1].actions[1] = {"recreateInt", "phq.quests.school_1_semestre", 1}
   ywMenuPushSlider(menu.ent, "Chapter Select: ", slider)
   menu:push("Quests", Entity.new_func("cheat_quest_select_mn"))
   menu:push("NPCs")
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
   popSpendXpWid(mn)
   return backToGame(f)
end

function cheat_quest_select_mn(main_mn)
   --local quest_action = Entity.new_array()
   --quest_action[0] = {"increaseInt", yeGetInt(cu)}
   --quest_action[1] = {"phq.backToGame"}
   print("heja")
   local cnt = ywCntWidgetFather(main_mn)
   local qmn = Menu.new_entity()

   qmn.ent["pre-text"] = "Quest Cheat Menu"
   qmn:push("Back", Entity.new_func("cheat_main_mn"))
   for i = 0, yeLen(phq.quests) - 1 do
      qmn:push(yeGetKeyAt(phq.quests, i), Entity.new_func("cheat_quest_action"))
   end
   qmn.ent.size = 30
   ywReplaceEntry(cnt, 0, qmn.ent)
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

