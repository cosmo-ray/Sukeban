local phq = Entity.wrapp(ygGet("phq"))

local function mk_main_mn()
   local menu = Menu.new_entity()
   menu.ent["pre-text"] = "Cheat Menu, mainly here for debuging purpose"
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
   --local quest_action = Entity.new_array()
   --quest_action[0] = {"increaseInt", yeGetInt(cu)}
   --quest_action[1] = {"phq.backToGame"}
   menu:push("Quest Advance")
   menu:push("NPCs")
   return menu.ent
end

function god_window(mn)
   local m = main_widget
   local ccw = Container.new_entity("vertical")
   ccw.ent.background = "rgba: 255 255 255 255"

   ccw.ent.entries[0] = mk_main_mn()
   ywPushNewWidget(m, ccw.ent)
   return YEVE_ACTION
end

