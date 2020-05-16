local tiled = Entity.wrapp(ygGet("tiled"))
local lpcs = Entity.wrapp(ygGet("lpcs"))
local phq = Entity.wrapp(ygGet("phq"))
local modPath = Entity.wrapp(ygGet("phq.$path")):to_string()
local npcs = Entity.wrapp(ygGet("phq.npcs"))
local scenes = Entity.wrapp(ygGet("phq.scenes"))
local stores = Entity.wrapp(ygGet("phq.stores"))

GM_INV_IDX = 0
GM_STATS_IDX = 1
GM_QUEST_IDX = 2
GM_MAP_IDX = 3
GM_MISC_IDX = 4

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

function openGlobMenu(main, on_idx, arg0)
   local mn = Container.new_entity("horizontal")
   --mn.ent.action = Entity.new_func("backToGameOnEnter")
   mn.ent.background = "rgba: 155 155 255 190"
   mn.ent.auto_foreground = "rgba: 0 0 120 50"

   if arg0 then
      backToGame(main)
      main = main_widget
      on_idx = yeGetInt(arg0)
      usable_metro = true
   end
   local panel = Menu.new_entity()
   local lf = Entity.new_func("gmLooseFocus")
   panel.ent["mn-type"] = "panel"
   panel:push("Inventory", lf)
   panel:push("Status", lf)
   panel:push("Quests")
   panel:push("Map", lf)
   panel:push("MISC (and boo)", lf)
   panel.ent.in_subcontained = 1
   panel.ent.size = 5
   panel.ent.moveOn = Entity.new_func("globMnMoveOn")
   panel.ent.onEsc = Entity.new_func("backToGame2")
   local on_down = Entity.new_array()
   on_down[0] = Y_DOWN_KEY
   on_down[1] = lf
   panel.ent.on = {}
   panel.ent.on[0] = on_down

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
   txt_screen.action = Entity.new_func("gmGetBackFocus")
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
   local cmb_str = "-[Currrent Combot: {phq.pj.attack}]-\n"

   local i = 0
   while i < yeLen(knowledge) do
      if knowledge[i] then
	 knowledge_str = knowledge_str .. yeGetKeyAt(knowledge, i) ..
	    ": {phq.pj.knowledge." .. math.floor(i) .. "}\n"
      end
      i = i + 1
   end
   local i = 0
   while i < yeLen(stats) do
      if stats[i] then
	 stats_str = stats_str .. yeGetKeyAt(stats, i) ..
	    ": {phq.pj.stats." .. math.floor(i) .. "}\n"
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

   local chap_txt = "capter: "

   if yeGetInt(phq.env.chapter) < 1 then
      chap_txt = chap_txt .. "Prologue"
   else
      chap_txt = chap_txt .. yeGetInt(phq.env.chapter)
   end
   txt_screen["<type>"] = "text-screen"
   txt_screen["text-align"] = "center"
   txt_screen.fmt = "yirl"
   txt_screen.text = chap_txt .. "\nDay: " ..
      DAY_STR[phq.env.day:to_int() + 1] .. ", {phq.env.time}\n" ..
      "week: {phq.env.week}\n" ..
      "time point: {phq.env.time_point}\n" ..
      "Status:\n" ..
      "life: {phq.pj.life}\n" ..
      "xp: {phq.pj.xp} \n" ..
      alcohol_lvl_str() ..
      knowledge_str ..
      stats_str ..
      cmb_str
   txt_screen.background = "rgba: 155 155 255 190"
   ywPushNewWidget(container, txt_screen)
end

function alcohol_lvl_str()
   if (phq.pj.drunk:to_int() > 1) then
      return "alcohol level: {phq.pj.drunk}\n"
   end
   return ""
end

function popGlobMnOtherMenu(mn)
   local main = ywCntWidgetFather(ywCntWidgetFather(mn))

   ywCntPopLastEntry(main)
   return YEVE_ACTION
end

function spendXpBack(mn)
   local main = ywCntWidgetFather(mn)

   ywCntPopLastEntry(main)
   return YEVE_ACTION
end

function computeStatCost(st_val)
   return (st_val + 1) * 3
end

local function computeXpCost(player)
   local ml = player.max_life:to_int()

   ml = ml - 10
   local multiplier = ml / 5
   return 1 + multiplier
end

function spendXpLvlUpStat(mn)
   local stats = phq.pj.stats
   local st_idx = yeGetIntAt(ywMenuGetCurrentEntry(mn), "arg")
   local st_val_ent = yeGet(stats, st_idx)
   local st_val = yeGetInt(st_val_ent)
   local cost = computeStatCost(st_val)

   print("spendXpLvlUpStat", ywMenuGetCurrentEntry(mn))
   print(Entity.wrapp(ywMenuGetCurrentEntry(mn)).arg,
	 st_val, cost, cost < phq.pj.xp)
   if cost < phq.pj.xp then
      phq.pj.xp = phq.pj.xp - cost
      yeSetInt(st_val_ent, st_val + 1)
   else
      print("someday, you will improve ",
	    yeGetKeyAt(stats, st_idx),
	    " but this day is not today !")
   end
   spendXpGenMenu(Menu.wrapp(mn))
   return YEVE_ACTION
end


function sendXpLvlUpXp(mn)
   local player = phq.pj
   local ml = player.max_life
   local life = player.life
   local cost = computeXpCost(player)

   if cost < player.xp then
      player.xp = player.xp - cost
      yeSetInt(life, life + 1)
      yeSetInt(ml, ml + 1)
   else
      print("someday, you be stronger but this day is not today !")
   end

   spendXpGenMenu(Menu.wrapp(mn))
   return YEVE_ACTION
end

function spendXpGenMenu(statsMenu)
   local stats = phq.pj.stats

   statsMenu.ent["pre-text"] = "current xp: " .. yeGetInt(phq.pj.xp)
   statsMenu.ent.entries = {}
   statsMenu:push("<----", Entity.new_func("spendXpBack"))
   local i = 0
   while i < yeLen(stats) do
      if stats[i] then
	 local st_val = yeGetInt(stats[i])
	 local stats_str = yeGetKeyAt(stats, i) .. "(" ..
	    math.floor(st_val) .. "): " ..
	    math.floor(computeStatCost(st_val)) .. " xp"
	 statsMenu:push(stats_str, Entity.new_func("spendXpLvlUpStat"), i)
      end
      i = i + 1
   end
   local xp_cost = math.floor(computeXpCost(phq.pj))
   statsMenu:push("max life: (" .. phq.pj.max_life:to_int() .. "): "
		     .. xp_cost .. " xp", Entity.new_func("sendXpLvlUpXp"))
end

function spendXpOnStats(mn)
   local main = ywCntWidgetFather(mn)
   local statsMenu = Menu.new_entity()

   spendXpGenMenu(statsMenu)
   ywPushNewWidget(main, statsMenu.ent)
   return YEVE_ACTION
end

function increase_recover_lvl(mn)
   phq.pj.recover_level = yeGetIntAt(phq.pj, "recover_level") + 1
   return YEVE_ACTION
end

local function genLearnableSkill(nmn)
   local cmbs = phq.pj.combots
   local leanable_cmbs = phq.skills.combots
   local recover_improvement = phq.skills.recovers
   local i = 0

   print(phq.pj.combots)
   print(phq.skills.combots)
   nmn.ent["pre-text"] = "current xp: " .. yeGetInt(phq.pj.xp)
   nmn.ent.entries = {}

   nmn:push( "<----", Entity.new_func("spendXpBack"))
   while i < yeLen(leanable_cmbs) do
      local ccmb = leanable_cmbs[i]
      local cmb_name = yeGetKeyAt(leanable_cmbs, i)

      if yIsNNil(yeFindString(cmbs, cmb_name)) then
	 goto next
      end
      nmn:push(cmb_name .. " : " .. ccmb.cost:to_int(),
	       Entity.new_func("learnSkillCombot"), cmb_name)
      :: next ::
      i = i + 1
   end
   local r_level = yeGetIntAt(phq.pj, "recover_level")
   local r_name = yeGetKeyAt(recover_improvement, r_level)
   local r_skill = recover_improvement[r_level]

   nmn:push(r_name .. " : " .. r_skill.cost:to_int(),
	    Entity.new_func("increase_recover_lvl"))
end

function learnSkillCombot(mn)
   print("learn combot:", Entity.wrapp(ywMenuGetCurrentEntry(mn)))
   learn_combot(yeGetStringAt(ywMenuGetCurrentEntry(mn), "arg"))
   genLearnableSkill(Menu.wrapp(mn))
   return YEVE_ACTION
end

function learnableSkill(mn)
   local main = ywCntWidgetFather(mn)
   local nmn = Menu.new_entity()

   genLearnableSkill(nmn)
   ywPushNewWidget(main, nmn.ent)
   return YEVE_ACTION
end

function pushSpendXpWid(mn)
   -- 1: get status vertical container
   -- 2: get global menu horizontal container
   -- 3: get main stacking container
   local main = ywCntWidgetFather(ywCntWidgetFather(ywCntWidgetFather(mn)))
   main = Entity.wrapp(main)
   local lvlUp = Container.new_entity("vertical")
   lvlUp.ent.background = "rgba: 255 255 255 255"

   local menu = Menu.new_entity()
   menu:push("finish", Entity.new_func("popGlobMnOtherMenu"))
   menu:push("improve stats", Entity.new_func("spendXpOnStats"))
   menu:push("learn skills", Entity.new_func("learnableSkill"))
   lvlUp.ent.entries[0] = menu.ent
   menu.ent.size = 20
   ywPushNewWidget(main, lvlUp.ent)
   return YEVE_ACTION
end

function setCmbAsAttack(mn)
   print("set smb !", "current: " .. phq.pj.attack:to_string(),
	 yeGetStringAt(mn, "pre-text"))
   print(Entity.wrapp(ywMenuGetCurrentEntry(mn)))
   phq.pj.attack = Entity.wrapp(ywMenuGetCurrentEntry(mn)).text
   yeSetAt(mn, "pre-text", "current: " .. phq.pj.attack:to_string())
end

function chooseCombot(mn)
   print("choose combot")
   local cmbs = phq.pj.combots
   local m = main_widget
   local ccw = Container.new_entity("vertical")
   ccw.ent.background = "rgba: 255 255 255 255"
   local menu = Menu.new_entity()
   local i = 0

   menu.ent["pre-text"] = "current: " .. phq.pj.attack:to_string()
   menu:push("back", Entity.new_func("popGlobMnOtherMenu"))
   menu.ent.onEsc = Entity.new_func("popGlobMnOtherMenu")
   while i < yeLen(cmbs) do
      local cmb = cmbs[i]
      menu:push(cmb:to_string(), Entity.new_func("setCmbAsAttack"))
      i = i +  1
   end
   ccw.ent.entries[0] = menu.ent
   --menu.ent.size = 20
   ywPushNewWidget(m, ccw.ent)
   return YEVE_ACTION
end

function wear_cloth(mn)
   mn = Entity.wrapp(mn)
   local desc = Entity.wrapp(yeGet(ywMenuGetCurrentEntry(mn), "arg"))
   local where = yeGetString(desc.where)
   local eq = phq.pj.equipement

   if (desc.where == "torso" or desc.where == "legs") and
   (desc.full_body or eq.full_body) then
      eq.torso = nil
      eq.legs = nil
   end
   eq[where] = yeGetString(desc.key_name)
   dressUp(phq.pj)
   lpcs.handlerReload(yeGet(main_widget, "pj"))
   lpcs.handlerReload(mn.pj)
   return YEVE_ACTION
 end

function wear_clothes_mn(mn)
   local m = main_widget
   local ccw = Container.new_entity("vertical")
   ccw.ent.background = "rgba: 255 255 255 255"
   local menu = Menu.new_entity()
   local inv = phq.pj.inventory
   local i = 0

   --menu.ent["pre-text"] = "current: " .. phq.pj.attack:to_string()
   local c = Canvas.new_entity()
   menu.ent.pj = lpcs.createCaracterHandler(phq.pj, c.ent)
   ylpcsHandlerSetPos(menu.ent.pj, Pos.new(20, 10).ent)
   lpcs.handlerSetOrigXY(menu.ent.pj, 0, 10)
   lpcs.handlerRefresh(menu.ent.pj)

   menu:push("back", Entity.new_func("popGlobMnOtherMenu"))
   menu.ent.onEsc = Entity.new_func("popGlobMnOtherMenu")
   while i < yeLen(inv) do
      local name = yeGetKeyAt(inv, i)
      local ob_desc = phq.objects[name]

      print(ob_desc, yIsNil(ob_desc), (yeGetStringAt(ob_desc, "type") ~= "equipement"))
      if yIsNil(ob_desc) or (yeGetStringAt(ob_desc, "type") ~= "equipement") then
	 goto next
      end
      ob_desc.key_name = name

      if ob_desc.name then
	 name = ob_desc.name:to_string()
      end

      menu:push(name, Entity.new_func("wear_cloth"), ob_desc)
      :: next ::
      i = i +  1
   end
   ccw.ent.entries[0] = menu.ent
   ccw.ent.entries[1] = c.ent
   --menu.ent.size = 20
   ywPushNewWidget(m, ccw.ent)
   return YEVE_ACTION
end

function alliesMoveOn(mn)
   print("allies move on !\n")
end

function allies_mn(mn)
   local m = main_widget
   local ccw = Container.new_entity("vertical")
   ccw.ent.background = "rgba: 255 255 255 255"
   local menu = Menu.new_entity()
   local allies = phq.pj.allies
   -- TODO ALLIES SCREEN

   ccw.ent.entries[0] = menu.ent
   menu:push("back", Entity.new_func("popGlobMnOtherMenu"))
   menu.ent.onEsc = Entity.new_func("popGlobMnOtherMenu")
   for i = 0, yeLen(allies) do
      menu:push(yeGetKeyAt(allies, i))
   end
   ywPushNewWidget(m, ccw.ent)
   menu.ent.moveOn = Entity.new_func("alliesMoveOn")
   return YEVE_ACTION
end

function doAdvanceTime(mn)
   local f_mn = ywCntWidgetFather(mn)

   backToGame(f_mn)
   advance_time(main_widget)
end

function gotoEndChapter(mn)
   local f_mn = ywCntWidgetFather(mn)

   backToGame(f_mn)
   phq.env.day = 7
   phq.env.time = "night"
   sleep(main_widget)
end

function pushStatus(mn)
   local gm_cnt = Entity.wrapp(ywCntWidgetFather(mn))
   local main = main_widget
   local stat_menu = Container.new_entity("vertical")
   local hooks = main.gmenu_hook

   ywCntPopLastEntry(gm_cnt)
   ywPushNewWidget(gm_cnt, stat_menu.ent)
   stat_menu.ent.isChildContainer = true

   local menu = Menu.new_entity()
   menu:push("Spend XP", Entity.new_func("pushSpendXpWid"))
   menu:push("Choose Combot", Entity.new_func("chooseCombot"))
   menu:push("wear clothes", Entity.new_func("wear_clothes_mn"))
   menu:push("God Mode", Entity.new_func("god_window"))
   menu:push("advence time", Entity.new_func("doAdvanceTime"))
   menu:push("Allies", Entity.new_func("allies_mn"))
   if is_end_of_chapter then
      menu:push("end chapter", Entity.new_func("gotoEndChapter"))
   end
   local i = 0
   while  i < yeLen(hooks) do
      local h = hooks[i]
      print(hooks[i])
      if (h[0]:to_int() == GM_STATS_IDX) then
	 h[1](main, menu.ent)
      end
      i = i + 1
   end

   menu.ent.size = 30
   menu.ent.onEsc = Entity.new_func("gmGetBackFocus")
   stat_menu.ent.entries[0] = menu.ent
   ywCntConstructChilds(gm_cnt)
   pushSTatusTextScreen(stat_menu.ent)
   stat_menu.ent.current = 0
   return YEVE_ACTION
end

local function doItemsListening(mn)
   local inv = phq.pj.inventory
   local i = 0

   mn.ent.entries = {}
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
end

function gmUseItem(mn)
   local main = Entity.wrapp(ywCntWidgetFather(mn))
   local cur = Entity.wrapp(ywMenuGetCurrentEntry(mn))
   local objs_list = phq.objects
   local o_str = cur.obName
   local o = objs_list[o_str:to_string()]
   local been_used = false
   print(objs_list:cent())

   if yIsNil(o) then
      return YEVE_NOTHANDLE
   end
   print("use o", o:cent())
   if o.type:to_string() == "book" then
      return read_book(o, o_str)
   end
   if o.func then
      if yeType(o.func) == YFUNCTION then
	 o.func(main, o)
      else
	 yesCall(ygGet(o.func:to_string()), main:cent(), o:cent())
      end
      been_used = true
   elseif o["stats+"] then
      local stats_p = o["stats+"]

      been_used = true
      local i = 0
      while i < yeLen(stats_p) do
	 increaseStat(mn, phq.pj, yeGetKeyAt(stats_p, i),
		      yeGetIntAt(stats_p, i))
	 i = i + 1
      end
   end
   if been_used then
      remove(mn, nil, o_str)
   end
   doItemsListening(Menu.wrapp(mn))
end

function invList(mn)
   local main = Entity.wrapp(ywCntWidgetFather(mn))
   ywCntPopLastEntry(main)
   mn = Menu.new_entity()
   doItemsListening(mn)
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

function storeMoveOn(mn, current)
   local cur = Entity.wrapp(ywMenuGetCurrentEntry(mn))
   local img_p = cur.path
   local cnt = ywCntWidgetFather(mn)
   local cv = ywCntGetEntry(cnt, 1)

   ywCanvasClear(cv)
   if yIsNNil(img_p) then
      local r = Rect.new(lpcs.x_threshold:to_int(),
			 lpcs.y_threshold:to_int(),
			 lpcs.w_sprite:to_int(),
			 lpcs.h_sprite:to_int())

      ywContainerUpdate(cnt, cv)
      cv = Canvas.wrapp(cv)
      local ob = cv:new_img(
	 0, 0,
	 yeGetString(lpcs["$path"]) .. "/" .. "spritesheets" .. "/" .. yeGetString(img_p), r.ent)
      ob:force_size(Size.new(100,200))
      print("LEN", yeLen(cv.ent.objs))
   end
   print(cur.cost, cur.obName, yeGetString(lpcs["$path"]),
	 cur.path, yIsNNil(cur.path))
   return YEVE_ACTION;
end

function openStore(main, obj_or_eve, storeName)
   main = Entity.wrapp(main)
   print(main.isDialogue)
   if main.isDialogue then
      main = Entity.wrapp(ywCntWidgetFather(yDialogueGetMain(main)))
      ywCntPopLastEntry(main)
   end
   storeName = yeGetString(storeName)
   print("open ", storeName, stores[storeName])

   local store = stores[storeName]
   local cnt = Container.new_entity("vertical")

   local cv = Canvas.new_entity()
   local mn = Menu.new_entity()

   mn.ent.in_subcontained = 1
   mn:push("Exit Store", Entity.new_func("backToGame"))
   mn.ent.onEsc = Entity.new_func("backToGame")

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
	 if yIsNil(yeGet(ob_desc, "path")) then
	    cur.path = nil
	 else
	    cur.path = yeGet(ob_desc, "path")
	 end
	 cur.cost = cost
      end
      i = i + 1
   end
   mn.ent.moveOn = Entity.new_func("storeMoveOn")
   mn.ent.size = 40
   cnt.ent.background = "rgba: 255 255 255 190"
   cnt.ent.entries[0] = mn.ent
   cnt.ent.entries[1] = cv.ent
   ywPushNewWidget(main, cnt.ent)
   return YEVE_ACTION
end

function howtoplay(mn)
   local mncp = Entity.new_copy(ygGet("phq:menus.bagare"))

   mncp.action = Entity.new_func("backToGameOnEnter")
   ywPushNewWidget(main_widget, mncp)
end

function fillMiscMenu(mn)
   print("fill time !")
   mn = Menu.wrapp(mn)
   mn.ent.entries = {}
   mn:push("quick save", Entity.new_func("saveGameCallback"))
   mn:push("save", Entity.new_func("saveGameMenu"))
   mn:push("main menu", "callNext")
   mn:push("How to Play", Entity.new_func("howtoplay"))
   mn:push("Back To Game", "phq.backToGame")
   mn.ent.background = "rgba: 255 255 255 190"
   mn.ent["text-align"] = "center"
end

function saveSlot(mn)
   local slot = Entity.wrapp(ywMenuGetCurrentEntry(mn)).slot:to_string()
   print("save on ", slot)
   saveGame(main_widget, slot)
   printMessage(main_widget, nil, "save on slot: " .. slot)
end

function saveGameMenu(mn)
   print("push save game menu ?")
   local e = nil
   mn = Entity.wrapp(mn)
   mn.entries = {}
   mn = Menu.wrapp(mn)
   mn:push("back", Entity.new_func("fillMiscMenu"))
   e = mn:push("slot 0", Entity.new_func("saveSlot"))
   e.slot = "slot_0"
   e = mn:push("slot 1", Entity.new_func("saveSlot"))
   e.slot = "slot_1"
   e = mn:push("slot 2", Entity.new_func("saveSlot"))
   e.slot = "slot_2"
   e = mn:push("slot 3", Entity.new_func("saveSlot"))
   e.slot = "slot_3"
   e = mn:push("slot 4", Entity.new_func("saveSlot"))
   e.slot = "slot_4"
   e = mn:push("slot 5", Entity.new_func("saveSlot"))
   e.slot = "slot_5"
   e = mn:push("slot 6", Entity.new_func("saveSlot"))
   e.slot = "slot_6"
   e = mn:push("slot 7", Entity.new_func("saveSlot"))
   e.slot = "slot_7"
   e = mn:push("slot 8", Entity.new_func("saveSlot"))
   e.slot = "slot_8"
   e = mn:push("slot 9", Entity.new_func("saveSlot"))
   e.slot = "slot_9"
   e = mn:push("slot A", Entity.new_func("saveSlot"))
   e.slot = "slot_A"
   e = mn:push("slot B", Entity.new_func("saveSlot"))
   e.slot = "slot_B"
   e = mn:push("slot C", Entity.new_func("saveSlot"))
   e.slot = "slot_C"
   e = mn:push("slot D", Entity.new_func("saveSlot"))
   e.slot = "slot_D"
   e = mn:push("slot E", Entity.new_func("saveSlot"))
   e.slot = "slot_E"
   e = mn:push("slot F", Entity.new_func("saveSlot"))
   e.slot = "slot_F"
   e = mn:push("slot 10", Entity.new_func("saveSlot"))
   e.slot = "slot_10"
end
