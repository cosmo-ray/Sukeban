local tiled = Entity.wrapp(ygGet("tiled"))
local lpcs = Entity.wrapp(ygGet("lpcs"))
local phq = Entity.wrapp(ygGet("phq"))
local modPath = Entity.wrapp(ygGet("phq.$path")):to_string()
local npcs = Entity.wrapp(ygGet("phq.npcs"))
local scenes = Entity.wrapp(ygGet("phq.scenes"))
local stores = Entity.wrapp(ygGet("phq.stores"))

GM_BACK_IDX = 0
GM_INV_IDX = 1
GM_STATS_IDX = 2
GM_QUEST_IDX = 3
GM_MAP_IDX = 4
GM_MISC_IDX = 5

function globMnMoveOn(menu, current)
   local main = Entity.wrapp(ywCntWidgetFather(menu))

   current = yLovePtrToNumber(current)
   if current == GM_INV_IDX then
      invList(menu)
   elseif current == GM_STATS_IDX then
      pushStatus(menu)
   elseif current == GM_QUEST_IDX then
      pushQuests(menu)
   elseif current == GM_MISC_IDX then
      ywCntPopLastEntry(main)
      pushMainMenu(main)
   elseif current == GM_MAP_IDX then
      ywCntPopLastEntry(main)
      pushMetroMenu(main)
   elseif current == GM_BACK_IDX then
      local ts = Entity.new_array()
      ts["<type>"] = "text-screen"
      ts.text = "Back To Game"
      ywCntPopLastEntry(main)
      ywPushNewWidget(main, ts)
   end
   main.entries[1].in_subcontained = 1
   main.current = 0
   return YEVE_NOACTION;
end

function gmLooseFocus(mn)
   local main = Entity.wrapp(ywCntWidgetFather(mn))

   main.current = 1
   return YEVE_NOACTION;
end

function gmGetBackFocus(mn)
   local main = Entity.wrapp(ywCntWidgetFather(mn))

   if main.isChildContainer then
      main = Entity.wrapp(ywCntWidgetFather(main))
   end
   main.current = 0
   return YEVE_NOACTION;
end

function openGlobMenu(main, on_idx)
   local mn = Container.new_entity("horizontal")
   --mn.ent.action = Entity.new_func("backToGameOnEnter")
   mn.ent.background = "rgba: 155 155 255 190"
   mn.ent.auto_foreground = "rgba: 0 0 120 50"

   local panel = Menu.new_entity()
   local lf = Entity.new_func("gmLooseFocus")
   panel.ent["mn-type"] = "panel"
   panel:push("Back", "phq.backToGame")
   panel:push("Inventory", lf)
   panel:push("Status", lf)
   panel:push("Quests")
   panel:push("Map", lf)
   panel:push("MICS (and boo)", lf)
   panel.ent.in_subcontained = 1
   panel.ent.size = 5
   panel.ent.moveOn = Entity.new_func("globMnMoveOn")

   local ts = Entity.new_array()
   ts["<type>"] = "text-screen"
   ts.text = ""
   mn.ent.entries[0] = panel.ent
   mn.ent.entries[1] = ts

   ywPushNewWidget(main, mn.ent)
   ywCntConstructChilds(main)
   ywMenuMove(panel.ent, on_idx)
   return YEVE_ACTION
end

function pushQuests(panel)
   local main = ywCntWidgetFather(panel)
   local txt = "----- quests -----\n"

   ywCntPopLastEntry(main)
   local txt_screen = Entity.new_array()

   -- quests_info
   local i = 0
   while i < yeLen(quests_info) do
      local quest_name = yeGetString(quest_name)
      local quest = quests_info[i]
      local stalk_sart = yeGetIntAt(quest, "stalk_sart")
      local stalk_path = yeGetStringAt(quest, "stalk")
      local cur = yeGetInt(ygGet(stalk_path))

      if (cur > stalk_sart) then
	 local descs = quest.descriptions
	 txt = txt .. "[ " ..  yeGetKeyAt(quests_info, i) .. " ]\n"
	 if cur >= yeLen(descs) then
	    txt = txt .. "completed !\n"
	 else
	    txt = txt .. yeGetStringAt(descs, cur) .. "\n"
	 end
      end
      i = i + 1
   end

   -- widget boring stuff
   txt_screen["<type>"] = "text-screen"
   txt_screen["text-align"] = "center"
   txt_screen.text = txt
   txt_screen.background = "rgba: 155 155 255 190"
   ywPushNewWidget(main, txt_screen)
end

function pushSTatusTextScreen(container)
   local txt_screen = Entity.new_array()
   local knowledge_str = "----- Knowledge -----\n"
   local knowledge = phq.pj.knowledge
   local stats_str = "----- Stats -----\n"
   local stats = phq.pj.stats
   local trait_str = "----- Trait -----\n"
   local trait = phq.pj.trait

   local i = 0
   while i < yeLen(knowledge) do
      if knowledge[i] then
	 knowledge_str = knowledge_str ..
	    yeGetKeyAt(knowledge, i) .. ": " .. yeGetInt(knowledge[i]) .. "\n"
      end
      i = i + 1
   end
   local i = 0
   while i < yeLen(stats) do
      if stats[i] then
	 stats_str = stats_str ..
	    yeGetKeyAt(stats, i) .. ": " .. yeGetInt(stats[i]) .. "\n"
      end
      i = i + 1
   end
   local i = 0
   while i < yeLen(trait) do
      if trait[i] then
	 trait_str = trait_str ..
	    yeGetKeyAt(trait, i) .. ": " .. yeGetInt(trait[i]) .. "\n"
      end
      i = i + 1
   end

   txt_screen["<type>"] = "text-screen"
   txt_screen["text-align"] = "center"
   txt_screen.text = "Day: " ..
      DAY_STR[phq.env.day:to_int() + 1] .. ", " ..
      phq.env.time:to_string() .. ", " ..
      "week: " .. phq.env.week:to_string() .. "\n" ..
      "Status:\n" ..
      "life: " .. phq.pj.life:to_int() .. "\n" ..
      "xp: " .. phq.pj.xp:to_int() .. "\n" ..
      "alcohol level: " .. phq.pj.drunk:to_int() .. "\n" ..
      knowledge_str .. stats_str
   txt_screen.background = "rgba: 155 155 255 190"
   ywPushNewWidget(container, txt_screen)
end

function popSpendXpWid(mn)
   local main = ywCntWidgetFather(ywCntWidgetFather(mn))

   ywCntPopLastEntry(main)
   return YEVE_ACTION
end

function spendXpBack(mn)
   local main = ywCntWidgetFather(mn)

   ywCntPopLastEntry(main)
   return YEVE_ACTION
end

function spendXpLvlUpStat(mn)
   local stats = phq.pj.stats
   local st_idx = yeGetIntAt(ywMenuGetCurrentEntry(mn), "arg")

   print("spendXpLvlUpStat", ywMenuGetCurrentEntry(mn))
   print(Entity.wrapp(ywMenuGetCurrentEntry(mn)).arg,
	 yeGetKeyAt(stats, st_idx), yeGetIntAt(stats, st_idx))
end

function spendXpOnStats(mn)
   local main = ywCntWidgetFather(mn)

   local statsMenu = Menu.new_entity()
   local stats = phq.pj.stats

   statsMenu.ent["pre-text"] = "current xp: " .. yeGetInt(phq.pj.xp)
   statsMenu:push("<----", Entity.new_func("spendXpBack"))
   local i = 0
   while i < yeLen(stats) do
      if stats[i] then
	 local st_val = yeGetInt(stats[i])
	 local stats_str = yeGetKeyAt(stats, i) .. "(" ..
	    math.floor(st_val) .. "): " ..
	    math.floor((st_val + 1) * 3) .. " xp"
	 statsMenu:push(stats_str, Entity.new_func("spendXpLvlUpStat"), i)
      end
      i = i + 1
   end

   ywPushNewWidget(main, statsMenu.ent)
   return YEVE_ACTION
end

function pushSpendXpWid(mn)
   -- 1: get status vertical container
   -- 2: get global menu horizontal container
   -- 3: get main stacking container
   local main = ywCntWidgetFather(ywCntWidgetFather(ywCntWidgetFather(mn)))
   print("hej hej peoples ", main, " here")
   main = Entity.wrapp(main)
   local lvlUp = Container.new_entity("vertical")
   lvlUp.ent.background = "rgba: 255 255 255 255"

   local menu = Menu.new_entity()
   menu:push("finish", Entity.new_func("popSpendXpWid"))
   menu:push("improve stats", Entity.new_func("spendXpOnStats"))
   menu:push("learn skills")
   lvlUp.ent.entries[0] = menu.ent
   menu.ent.size = 20
   ywPushNewWidget(main, lvlUp.ent)
   return YEVE_ACTION
end

function pushStatus(mn)
   local main = Entity.wrapp(ywCntWidgetFather(mn))
   local stat_menu = Container.new_entity("vertical")

   ywCntPopLastEntry(main)
   ywPushNewWidget(main, stat_menu.ent)
   stat_menu.ent.isChildContainer = true

   local menu = Menu.new_entity()
   menu:push("Spend XP", Entity.new_func("pushSpendXpWid"))
   menu.ent.size = 20
   menu.ent.onEsc = Entity.new_func("gmGetBackFocus")
   stat_menu.ent.entries[0] = menu.ent

   ywCntConstructChilds(main)
   pushSTatusTextScreen(stat_menu.ent)
   stat_menu.ent.current = 0
   return YEVE_ACTION
end

function gmUseItem(mn)
   local main = Entity.wrapp(ywCntWidgetFather(mn))
   local cur = Entity.wrapp(ywMenuGetCurrentEntry(mn))
   local objs_list = phq.objects
   local o = objs_list[cur.obName:to_string()]
   print(objs_list:cent())
   if o and o.func then
      if yeType(o.func) == YFUNCTION then
	 o.func(main, o)
      else
	 yesCall(ygGet(o.func:to_string()), main:cent(), o:cent())
      end
   end
   print("use item !!", cur.obName,
	 objs_list[cur.obName:to_string()])
end

function invList(mn)
   local main = Entity.wrapp(ywCntWidgetFather(mn))
   local inv = phq.pj.inventory
   ywCntPopLastEntry(main)
   mn = Menu.new_entity()
   local i = 0
   while i < yeLen(inv) do
      if inv[i] then
	 local name = yeGetKeyAt(inv, i)
	 local ob_desc = phq.objects[name]

	 if ob_desc and ob_desc.name then
	    name = ob_desc.name:to_string()
	 end
	 local cur = mn:push(name .. ": " ..
			     math.floor(yeGetInt(inv[i])),
			     Entity.new_func("gmUseItem"))
	 cur.obName = yeGetKeyAt(inv, i)
	 cur.inv_o = inv[i]
	 cur.inv = inv
      end
      i = i + 1
   end
   mn.ent.background = "rgba: 255 255 255 190"
   mn.ent.onEsc = Entity.new_func("gmGetBackFocus")
   ywPushNewWidget(main, mn.ent)
   return YEVE_ACTION
end

function gmBuyItem(mn)
   local main = Entity.wrapp(ywCntWidgetFather(mn))
   local cur = Entity.wrapp(ywMenuGetCurrentEntry(mn))
   local o_name = cur.obName:to_string()
   local who = phq.pj
   local cost = cur.cost:to_int()
   local money = who.inventory.money

   if money >= cost then
      yeSetInt(money, money:to_int() - cost)
      addObject(main, who, o_name, 1)
   else
      printMessage(main, obj, Entity.new_string("Not enouth money"))
   end
end

function openStore(main, obj_or_eve, storeName_or_arg, storeName)
   main = Entity.wrapp(main)
   print(main.isDialogue)
   if main.isDialogue then
      main = Entity.wrapp(ywCntWidgetFather(yDialogueGetMain(main)))
      ywCntPopLastEntry(main)
   else
      storeName = storeName_or_arg
   end
   storeName = yeGetString(storeName)
   print("open ", stores[storeName])

   local store = stores[storeName]
   mn = Menu.new_entity()
   mn:push("Exit Store", Entity.new_func("backToGame"))
   local i = 0
   while i < yeLen(store) do
      if store[i] then
	 local name = yeGetKeyAt(store, i)
	 local ob_desc = phq.objects[name]

	 if ob_desc and ob_desc.name then
	    name = ob_desc.name:to_string()
	 end
	 local cost = yeGetInt(store[i])
	 local cur = mn:push(name .. ": " ..
			     math.floor(cost) .. "$",
			     Entity.new_func("gmBuyItem"))
	 cur.obName = yeGetKeyAt(store, i)
	 cur.cost = cost
      end
      i = i + 1
   end
   mn.ent.background = "rgba: 255 255 255 190"
   ywPushNewWidget(main, mn.ent)
   return YEVE_ACTION
end
