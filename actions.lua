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

local sleep_time = 0
fight_script = nil
dialogue_npc = nil

local use_time_point_action = Entity.new_string("phq.use_time_point")

function next_time()
   local ret = Entity.new_array()

   ret.day = phq.env.day
   ret.week = phq.env.week
   if phq.env.time:to_string() == "night" then
      ret.time = "morning"
      ret.day = phq.env.day + 1
      if phq.env.day > 6 then
	 ret.day = 0
	 ret.week = phq.env.week + 1
      end
   elseif phq.env.time:to_string() == "morning" then
      ret.time = "day"
   else
      ret.time = "night"
   end
   return ret
end

function is_npc_ally(pj, npcname)
   local anpc = yeGet(pj.allies, npcname)

   return yIsNNil(anpc)
end

function read_book(b, b_key)
   local ts = Entity.new_array()
   ts["<type>"] = "text-screen"
   ts.text = "BOOK: " .. yeGetString(b_key) .. "\n" .. b.summary:to_string()
   ts.background = "rgba: 255 255 200 255"
   ts.actions = Entity.new_func(backToGameOnEnter)
   ywPushNewWidget(main_widget, ts)
   if yIsNNil(b.action) then
      if b.usable_once > 0 then
	 if yIsNil(phq.pj.used_items[b_key:to_string()]) then
	    phq.pj.used_items[b_key:to_string()] = 1
	    ywidAction(b.action, main_widget, nil)
	 end
      else
	 ywidAction(b.action, main_widget, nil)
      end
   end
   return YEVE_ACTION
end

function use_time_point(box)
   box = Entity.wrapp(box)
   if phq.env.time_point:to_int() == 0 then
      if yIsNil(box) or box.is_dialogue_condition == nil
      or box.is_dialogue_condition < 1 then
	 printMessage(main_widget, nil, "Not enough time point")
      end
      return Y_FALSE
   end

   if box and box.is_dialogue_condition then
      local answer = Entity.wrapp(yDialogueCurAnswer(box))
      local actions = answer.actions

      if yeDoesInclude(actions, use_time_point_action) == false then
	 yeInsertAt(actions, use_time_point_action, 0)
      end
   else
      phq.env.time_point = phq.env.time_point - 1
   end
   return Y_TRUE
end

function quest_try_Call_script(quest, qi_scripts, cur)
   local j = 0

   while j < yeLen(qi_scripts) do
      local at = yeGet(qi_scripts[j], "at")
      local callable = yeGetStringAt(qi_scripts[j], "call")

      if yIsNNil(at) and cur == yeGetInt(at) then
	 if (yIsNNil(callable)) then
	    yesCall(ygGet(callable))
	 else
	    scripts[yeGetStringAt(qi_scripts[j], "script")](main_widget)
	 end
      elseif yIsNNil(qi_scripts[j].after) and
	 cur > yeGetIntAt(qi_scripts[j], "after") and
	 cur < yeLenAt(quest, "descriptions") then

	 if (yIsNNil(callable)) then
	    yesCall(ygGet(callable))
	 else
	    scripts[yeGetStringAt(qi_scripts[j], "script")](main_widget)
	 end
      end
      j = j + 1
   end
end

function quest_update(original, _copy, arg)
   local main = yeGet(arg, 0)
   local quest_name = yeGet(arg, 1)
   quest_name = yeGetString(quest_name)
   local quest = quests_info[quest_name]
   local rewards = quest.rewards
   local r_idx = yeGetInt(original)
   local reward = yeGetIntAt(rewards, r_idx)
   local qi_scripts = quest.scripts

   quest_try_Call_script(quest, qi_scripts, r_idx)

   if reward ~= 0 then
      increaseStat(main, phq.pj, "xp", reward)
   end
end

function walkDoStep(_wid, character)
   if (math.abs(yeGetFloat(character.move.left_right)) > 0 or
       math.abs(yeGetFloat(character.move.up_down)) > 0)  then
      ylpcsHandlerNextStep(character)
      ylpcsHandlerRefresh(character)
   end
end

function backToGameOnEnter(wid, eve)
   eve = Event.wrapp(eve)

   while eve:is_end() == false do
      if eve:type() == YKEY_DOWN and (eve:key() == Y_ENTER_KEY or
				      eve:key() == Y_ESC_KEY) then
	 backToGame(wid)
      end
      eve = eve:next()
   end
   return YEVE_NOTHANDLE
end

function getMainWid(wid)
   wid = Entity.wrapp(wid)
   if wid:cent() == main_widget:cent() then
      return wid
   end

   if wid.isDialogue then
      wid = Entity.wrapp(yDialogueGetMain(wid))
   end
   if yeGetInt(wid.in_subcontained) == 1 then
      wid = Entity.wrapp(ywCntWidgetFather(wid))
   end
   local main = Entity.wrapp(ywCntWidgetFather(wid))
   return main
end

local function backToGameReset(main)
   local TIME_RESET = 1000000

   main.pj.move.up_down = 0
   main.pj.move.left_right = 0
   main.no_chktime_t = TIME_RESET
end

function backToGameDirOut()
   ygModDirOut()
   -- this need to be done in case submodule cange that
   tiled.setAssetPath("./tileset")
   return backToGame2()
end

function backToGame2()
   local main = main_widget
   local target = 2
   local c_t = 0

   if phq_only_fight > 0 then
      target = 3
      c_t = 2
   end

   while yeLen(main.entries)  > target do
      ywCntPopLastEntry(main)
   end

   main.current = c_t
   backToGameReset(main)
   return YEVE_ACTION
end

function backToGame(wid)
   if yIsNil(wid) or phq_only_fight > 0 then
      return backToGame2()
   end

   wid = Entity.wrapp(wid)
   if wid:cent() == main_widget:cent() then
      return
   end

   if wid.isDialogue then
      wid = Entity.wrapp(yDialogueGetMain(wid))
      wid.main = nil
      if wid.src then
	 wid.src.isBlock = wid.isBlock
	 wid.src.block = wid.block
	 wid.src = nil
      end
   end

   while yeGetInt(wid.in_subcontained) == 1 do
      wid = Entity.wrapp(ywCntWidgetFather(wid))
   end
   local main = Entity.wrapp(ywCntWidgetFather(wid))

   -- if not bailing out
   if yeGetStringAt(main, "<type>") ~= "phq" then
      return backToGame2()
   end

   if wid.oldTimer then
      main["turn-length"] = wid.oldTimer
   end
   local nb_layers = yeGetInt(wid.nb_layers)
   while nb_layers > 1 do
      ywCntPopLastEntry(main)
      nb_layers = nb_layers - 1
   end
   ywCntPopLastEntry(main)
   main.current = yeLen(main.entries) - 1
   backToGameReset(main)
   return YEVE_ACTION
end

function CombatEnd(wid, _main, winner_id)
   local main = main_widget
   wid = Entity.wrapp(wid)
   local upcanvas = Canvas.wrapp(main.upCanvas)
   local winner = Entity.wrapp(yJrpgGetWinner(wid, winner_id))
   local looser = Entity.wrapp(yJrpgGetLooser(wid, winner_id))

   ySoundStop(main.soundcallgirl)
   wid.main = nil
   if yLovePtrToNumber(winner_id) == 3 then
      -- you lose
      backToGame(wid)
      yNextLose(main:cent())
      return
   end
   upcanvas:remove(main.life_nb)
   main.life_nb = ywCanvasNewTextExt(upcanvas.ent, 410, 10,
				     Entity.new_string(math.floor(phq.pj.life:to_int())),
				     "rgba: 255 255 255 255")

   local fsstr = fight_script

   if fsstr == "CombatDialogueNext" or fsstr == "CombatDialogueGoto"
      or fsstr ==  "CombatDialogueStay" then
      ywCntPopLastEntry(main)
   else
      backToGame(wid)
   end
   return pushNewVictoryScreen(main, winner, looser)
   --print("end:", main, winner)
end


function npcDefaultInit(npc, enemy_type)
   if npc.is_generic then
      npc = Entity.new_copy(npc)
   end
   if yIsNil(npc.clothes) and yIsNNil(npc.equipement) then
      dressup.dressUp(npc)
   end
   if yIsNil(npc.name) then
      npc.name = enemy_type
   end
   if yIsNil(npc.max_life) then
      npc.max_life = 1
   end
   npc.life = npc.max_life
   if yIsNil(npc.attack) then
      npc.attack = "unarmed0"
   end
   npc.weapon = phq.combots[yeGetString(npc.attack)]
   print("NPC", npc.name, " WEAPON !!!!: ", npc.attack, npc.weapon, phq.combots )
   return npc
end

function StartFight(wid, eve, enemy_type, script)
   local main = getMainWid(wid)
   local fWid = Entity.new_array()
   local npc
   --ySoundPlayLoop(main.soundcallgirl:to_int())

   if yIsNNil(script) then
      if (yeType(script)) == YARRAY then
	 script = Entity.wrapp(script)
	 fight_script = yeGetString(script[0])
      else
	 fight_script = yeGetString(script)
      end
   end


   phq.pj.weapon = phq.combots[yeGetString(phq.pj.attack)]

   if (yIsNil(enemy_type)) then
      local swid = yDialogueGetMain(wid)
      swid = Entity.wrapp(swid)
      npc = main.npcs[swid.npc_nb:to_int()].char
      npc = npcDefaultInit(npc, "???")
   else
      if yeType(enemy_type) == YARRAY then
	 local i = 0
	 npc = Entity.new_array()
	 while i < yeLen(enemy_type) do
	    local enemy_type_i = yeGet(enemy_type, i)
	    npc[i] = npcs[yeGetString(enemy_type_i)]
	    npc[i] = npcDefaultInit(npc[i], enemy_type_i)
	    i = i + 1
	 end
      else
	 npc = npcs[yeGetString(enemy_type)]
	 if npc == nil then
	    npc = Entity.wrapp(ygGet(yeGetString(enemy_type)))
	    enemy_type = npc.name
	 end
	 npc = npcDefaultInit(npc, enemy_type)
      end
   end

   local player_array = Entity.new_array()
   local allies = phq.pj.allies

   player_array[0] = phq.pj
   if allies[0] then
      player_array[1] = allies[0]
      allies[0] = npcDefaultInit(allies[0], yeGetKeyAt(allies, 0))
      if allies[1] then
	 player_array[2] = allies[1]
	 allies[1] = npcDefaultInit(allies[1], yeGetKeyAt(allies, 1))
      end
   end
   fWid["<type>"] = "jrpg-fight"
   fWid.endCallback = Entity.new_func(CombatEnd)
   fWid.ychar_start = 80
   fWid.endCallbackArg = main
   fWid.player = player_array
   local usabel_items = Entity.new_array(phq.pj, "usable_items")
   local i = 0
   local inv = phq.pj.inventory
   while i < yeLen(inv) do
      local obj = phq.objects[yeGetKeyAt(inv, i)]
      if obj and yeGetStringAt(obj, "type") == "usable" then
	 usabel_items[yeGetKeyAt(inv, i)] = inv[i]
      end
      i  = i + 1
   end

   fWid.enemy = npc

   if fight_script == "CombatDialogueNext" then
      dialogue_mod.gotoNext(wid, eve)
   elseif fight_script == "RemoveEnemy" then
      local npc_a = main_widget.npc_act
      print("=dbg=")
      print(script)
      print(Entity.wrapp(script))
      print("-\\dbg-")
      local obj = main_widget.mainScreen.objects[script[1].obj_idx]

      if obj.no_respawn then
	 obj.dead = 1
      end
      if yIsNNil(obj.victory_action) then
	 npc.victory_action = obj.victory_action
	 if yIsNNil(obj.vapath) then
	    npc.vapath = obj.vapath
	 end
      end
      if obj.ai then
	 for j = 0, yeLen(npc_a) do
	    if yIsNNil(npc_a[j]) and script[1] == npc_a[j][ACTION_NPC] then
	       yeRemoveChild(wid.npc_act, j)
	       break
	    end
	 end
	 generic_handlerNullify(script[1])
      else
	 generic_handlerNullify(script[1])
	 yeRemoveChild(main.enemies, script[1])
      end
   elseif fight_script == "CombatDialogueGoto" then
      dialogue_mod["goto"](wid, eve, script[1])
   elseif fight_script ~= "CombatDialogueStay" then
      backToGame(wid, eve)
   end
   ywPushNewWidget(main, fWid)
   return YEVE_ACTION
end

function addObject(main, character, objStr, nb)
   local obj = character.inventory[objStr]
   local msg = "get "

   if yIsLuaNum(nb) == false and yeType(nb) == YARRAY then
      nb = Entity.wrapp(nb)
      local operation = yeGetString(nb[0]);
      local el0 = nb[1];
      local el1 = nb[2];

      if yeType(el0) == YSTRING then
	 el0 = ygGetInt(ygGet(yeGetString(el0)))
      end
      if yeType(el1) == YSTRING then
	 el1 = ygGet(yeGetString(el1))
      end
      el0 = yeGetInt(el0)
      el1 = yeGetInt(el1)
      if operation == "+" then
	 nb = el0 + el1
      elseif operation == "-" then
	 nb = el0 - el1
      elseif operation == "*" then
	 nb = el0 * el1
      elseif operation == "/" then
	 nb = el0 / el1
      end
   end

   if obj then
      local o_nb = yeGetInt(obj) + nb
      if o_nb == 0 then
	 character.inventory[objStr] = nil
      else
	 yeSetInt(obj, o_nb)
      end
   elseif nb > 0 then
      character.inventory[objStr] = nb
   else
      return YEVE_NOACTION
   end
   if (nb < 0) then
      msg = "lose "
      nb = nb * -1
   end
   return printMessage(main, obj, msg .. math.floor(nb) .. " " .. objStr)
end

function recive(_wid, _eve, objStr, nb)
   if yeType(nb) ~= YARRAY then
      nb = yeGetInt(nb)
      if nb == 0 then
	 nb = 1
      end
   end
   addObject(main_widget, phq.pj, yeGetString(objStr), nb)
end

function remove(_wid, _eve, objStr, nb)
   wid = main_widget
   nb = yeGetInt(nb)
   if nb == 0 then
      nb = -1
   else
      nb = -nb
   end
   addObject(wid, phq.pj, yeGetString(objStr), nb)
end

function takeObject(main, actionable_obj, what, nb)
   actionable_obj = Entity.wrapp(actionable_obj)

   if actionable_obj.is_used then
      return YEVE_ACTION
   end
   addObject(main, phq.pj, yeGetString(what), yeGetInt(nb))
   actionable_obj.is_used = true
end

function leave_team(who)
   printMessage(main_widget, nil, who .. " leave the Team !")
   yeRemoveChild(phq.pj.allies, who)
end

function leave_team_callback(_wid, _eves, who)
   leave_team(yeGetString(who))
end

function join_team(wid, _eves, who)
   local npcname = yeGetString(who)
   local npcidx = nil

   if yIsNil(who) then
      local m = yDialogueGetMain(wid)
      npcname = yeGetStringAt(m, "name")
      npcidx = yeGet(m, "npc_nb")
   end

   printMessage(main_widget, nil, npcname .. " have join the Team !")
   yePushBack(phq.pj.allies, npcs[npcname], npcname)

   if yIsNNil(npcidx) then
      npcidx = yeGetInt(npcidx)
      NpcGoTo(main_widget.npcs[npcidx], ylpcsHandePos(main_widget.pj))
   end
end

function go_under(_unused_wid, _unused_eve, entry)
   local wid = Entity.new_array()

   wid["<type>"] = "raycasting"
   wid.background = "rgba: 140 150 155 255";
   Entity.from_lua_arrray({
	 "#########",
	 "#......##",
	 "#..#...##",
	 "#..#...##",
	 "#.#.....#",
	 "#.#..#.##",
	 "#.#..#..#",
	 "#.#..#.##",
	 "#.#.....#",
	 "###.##..#",
	 "#....##.#",
	 "####.#..#",
	 "#########"
   }, wid, "map")
   wid.quit = Entity.new_func("backToGame")
   wid.exit_action = Entity.new_func(changeScene)
   wid.exits = {}
   wid.exits[0] = {1300, 8500, "up", "st_1", "street1", 7}
   wid.exits[1] = {1300, 10500, "up", "st_1_b", "hiden_house", 0}
   --wid.exits[1] = {1300, 6500, "up", "st_1_b", "hiden_house", 0}
   wid.entry = entry
   print(wid)
   ywPushNewWidget(main_widget, wid)
   return YEVE_ACTION
end

function pay(wid, eve, cost, okAction, noDialogue)
   cost = yeGetInt(cost)
   if phq.pj.inventory.money >= cost then
      local money = phq.pj.inventory.money
      yeSetInt(money, money:to_int() - cost)
      return ywidAction(okAction, wid, eve)
   end
   return dialogue_mod["change-text"](wid, eve, noDialogue)
end

function increaseStat(wid, stats_container, stat, nb, max_min)
   local s = Entity.wrapp(yeGetByStr(stats_container, stat))
   local opStr = "increase"

   yeSetInt(s, s:to_int() + nb)
   if nb < 0 then
      opStr = "decrease"
      if max_min and s < max_min then
	 yeSetInt(s, max_min)
      end
   else
      if max_min and s > max_min then
	 yeSetInt(s, max_min)
      end
   end
   return printMessage(wid, stats_container,
		       Entity.new_string(stat .. " " .. opStr .. " to " ..
					    math.floor(yeGetInt(s))))
end

function increase(_wid, _eve, whatType, what, val)
   local wid = main_widget
   if yeType(what) == YINT then
      val = what
      what = whatType
      return increaseStat(wid, phq.pj, yeGetString(what), yeGetInt(val))
   end
   local stat_container = phq.pj[yeGetString(whatType)]
   what = yeGetString(what)
   if stat_container[what] == nil then
      stat_container[what] = 0
   end
   return increaseStat(wid, stat_container, what, yeGetInt(val))
end

function tmp_increase(_wid, actionable_obj, what, val)
   actionable_obj = Entity.wrapp(actionable_obj)

   if actionable_obj.t and
      actionable_obj.t.d == phq.env.day and
      actionable_obj.t.t == phq.env.time and
      actionable_obj.t.w == phq.env.week
   then
      return YEVE_ACTION
   end

   val = yeGetInt(val)
   if yIsNil(phq.pj.tmp_stats) then
      phq.pj.tmp_stats = {}
   end
   local tsts = Entity.new_array(phq.pj.tmp_stats)
   tsts[0] = what
   tsts[1] = -val
   local s = "Increase: " .. yeGetString(what) .. " temporary of: " .. val
   printMessage(main_widget, nil, s)
   actionable_obj.t = {}
   actionable_obj.t.t = phq.env.time
   actionable_obj.t.d = phq.env.day
   actionable_obj.t.w = phq.env.week
   ygIncreaseInt(yeGetString(what), val)
end


function DrinkBeer(ent, obj)
   ent = Entity.wrapp(ent)
   local upcanvas = Canvas.wrapp(ent.upCanvas)
   local m = Entity.wrapp(main_widget)
   increaseStat(ent, phq.pj, "drunk", 9, 100)
   increaseStat(ent, phq.pj, "life", 2, phq.pj.max_life:to_int())

   upcanvas:remove(ent.life_nb)
   ent.life_nb = ywCanvasNewTextExt(upcanvas.ent, 410, 10,
				    Entity.new_string(math.floor(phq.pj.life:to_int())),
                                    "rgba: 255 255 255 255")
   if phq.pj.drunk > 99 then
      local indoorStr = ""
      if m.cur_scene.exterior then
	 indoorStr = "it has weird colors, maybe it's because you're indoor\n"
      end
      return printMessage(m, obj,
			  Entity.new_string(
			     -- TODO: fix borken english
			     "you lift up you head, look at the stared sky\n" ..
				indoorStr ..
				"it's funny how it move"))
   end
   return printMessage(m, obj, Entity.new_string("Glou Glou !"))
end

function GetDrink(wid, eve)
   local ent = Entity.wrapp(ywCntWidgetFather(yDialogueGetMain(wid)))

   addObject(ent, phq.pj, "beer", 1)
   return backToGame(wid, eve)
end

function call_quest_script(wid, _eve, script)
   scripts[yeGetString(script)](main_widget, wid)
   return YEVE_ACTION
end

cant_skip_time_reason = nil

-- in fact, this function do 2 things: adancing time and start sleep animation
function advance_time(_main, next_loc, force_skip_time, next_pos)
   main = main_widget
   if main.sleep_script then
      scripts[main.sleep_script:to_string()](main)
   end
   if force_skip_time then
      main.cant_skip_time = 0
   end
   if main.cant_skip_time and main.cant_skip_time > 0 then
      printMessage(main, nil, "Can't skip time: " .. cant_skip_time_reason)
      return
   end

   if yeType(next_loc) == YSTRING or type(next_loc) == "string" then
      main.sleep_loc = next_loc
      main.sleep_loc_pos = next_pos
   end
   npcAdvenceTime()
   local tmp_stats = phq.pj.tmp_stats
   for i = 0, yeLen(tmp_stats) - 1 do
      local st = tmp_stats[i]
      ygIncreaseInt(yeGetStringAt(st, 0), yeGetIntAt(st, 1))
   end
   yeClearArray(tmp_stats)
   if phq.env.time:to_string() == "night" then
      phq.env.time = "morning"
      phq.env.dayrand = yuiRand()
      phq.env.day = phq.env.day + 1
      if phq.env.day > 6 then
	 phq.env.day = 0
	 phq.env.week = phq.env.week + 1
      end
   elseif phq.env.time:to_string() == "morning" then
      phq.env.time = "day"
   else
      phq.env.time = "night"
   end
   -- I must handle season now
   local is_raining = 0
   if (yuiRand() % 3) == 0 then
      is_raining = 1
   end
   if is_raining then
      if phq.env.is_raining and is_raining > 0 then
	 phq.env.is_raining = phq.env.is_raining + 1
      else
	 phq.env.is_raining = is_raining
      end
   end
   phq.env.time_point = 1
   main.sleep = 1
   main.require_ret = 1
end

function sleep(_main, _obj)
   advance_time(main_widget)
   phq.pj.life = phq.pj.max_life
   phq.pj.drunk = 0
end

function printMessage(_main, _obj, msg)
   local txt = yLuaString(msg)
   local TIME_RESET = 1000000

   main = main_widget

   if (#txt > 30) then
      TIME_RESET = TIME_RESET * #txt / 30
   end
   if (yIsNil(main)) then
      return
   end
   if main.box then
      local txt_tmp = yeGetString(dialogue_box.get_text(main.box))
      if yIsNil(txt_tmp) then
	 return
      end
      txt = yeGetString(dialogue_box.get_text(main.box)) ..
	 "\n-------------------------------\n" .. txt
      dialogue_box.rm(main.upCanvas, main.box)
      main.box = nil
   end
   dialogue_box.new_text(main.upCanvas, 0, 0,
			 txt, main, "box")

   if main.box_t and main.box < 700000 then
      main.box_t = main.box_t + TIME_RESET
   else
      main.box_t = TIME_RESET
   end
end

local TMP_OBJ_SMALL_TALK = 0
local TMP_OBJ_CANVAS_OBJ = 1

function pushTmpCanvasObj(img, start_time)
   local tmp_objs = yeTryCreateArray(main_widget.upCanvas, "tmp-objs")
   local box = Entity.new_array(tmp_objs)

   if yIsNNil(start_time) then
      yeCreateInt(start_time, box)
   else
      yeCreateInt(0, box)
   end
   yeCreateInt(TMP_OBJ_CANVAS_OBJ, box)
   yePushBack(box, img)
end

function pushSmallTalk(txt, x, y, start_time)
   if type(txt) == "string" then
      txt = Entity.new_string(txt)
   end

   if yeType(txt) == YARRAY then
      if yeGetStringAt(txt, 0) == "rand" then
	 txt = yeGet(txt, yuiRand() % (yeLen(txt) - 1) + 1)
      else
	 txt = yeGet(txt, 0)
      end
   end

   local main = main_widget
   local uc = main.upCanvas
   local small_texts = yeTryCreateArray(uc, "tmp-objs")
   local txt_box = Entity.new_array(small_texts)
   local nb_nl = yeCountCharacters(txt, "\n", -1) + 1

   if yIsNNil(start_time) then
      yeCreateInt(start_time, txt_box)
   else
      yeCreateInt(0, txt_box)
   end
   yeCreateInt(TMP_OBJ_SMALL_TALK, txt_box)
   dialogue_box.new_text(uc, x - 40, y - (40 * nb_nl),
			 yeGetString(txt), txt_box)
end

function smallTalk(_main, c)
   --local n = npcs[yeGetInt(c.current)]
   local p = ywCanvasObjPos(c)
   local txt = c.small_talk

   pushSmallTalk(txt, ywPosX(p), ywPosY(p))
end

function tmpObjsRemover(main)
   local i = 0
   local uc = main.upCanvas
   local small_texts = yeGet(uc, "tmp-objs")
   local time = ywidTurnTimer() / 1000

   while (i < yeLen(small_texts)) do
      local sti = yeGet(small_texts, i)
      if yeGetIntAt(sti, 0) > 500 then
	 if yeGetIntAt(sti, 1) == TMP_OBJ_SMALL_TALK then
	    dialogue_box.rm(uc, yeGet(sti, 2))
	 elseif yeGetIntAt(sti, 1) == TMP_OBJ_CANVAS_OBJ then
	    ywCanvasRemoveObj(uc, yeGet(sti, 2))
	 else
	    print("can't remove obj of type: ", yeGetIntAt(sti, 1))
	 end
	 yeRemoveChild(small_texts, i)
      else
	 yeSetAt(sti, 0, yeGetIntAt(sti, 0) + time)
      end
      i = i + 1
   end
end

function npc_handler_from_canva(c)
   return main_widget.npcs[c.current:to_int()]
end

function startDialogue(_main, obj, dialogue)
   dialogue = Entity.wrapp(dialogue)
   if dialogue and dialogues[dialogue:to_string()] then
      obj = Entity.wrapp(obj)
      local condition = obj.dialogue_condition

      if yIsNNil(condition) and yeCheckCondition(condition) == false then
	 goto out
      end
      local dialogueWid = Entity.new_array()
      local npc
      local npc_nb = -1

      if obj.current then
	 npc = npc_handler_from_canva(obj).char
	 npc_nb = obj.current
      else
	 npc = obj
      end
      dialogue = dialogues[dialogue:to_string()]
      dialogue_npc = npc

      if dialogue.dialogue then
	 yeCopy(dialogue, dialogueWid)
	 dialogueWid.src = dialogue
      else
	 dialogueWid.dialogue = dialogue
      end
      dialogueWid.npc_nb = npc_nb
      dialogueWid["<type>"] = "dialogue-canvas"
      dialogueWid.image = npc.image
      dialogueWid.image_rotate = npc.image_rotate
      dialogueWid.name = npc.name
      dialogueWid.endAction = "phq.backToGame"
      main_widget.dialogue_npc = npc
      main_widget.require_ret = 1
      ywPushNewWidget(main_widget, dialogueWid)
      return YEVE_ACTION
   end
   :: out ::
   return YEVE_NOTHANDLE
end

function actionOrPrint(main, obj)
   obj = Entity.wrapp(obj)

   local condition = Entity.new_array()
   yeCreateString(yeGetString(obj.CheckOperation), condition)
   yePushBack(condition, obj.Check0)
   yePushBack(condition, obj.Check1)
   local ret = yeCheckCondition(condition)
   if ret then
      return yesCall(ygGet(obj.SucessAction:to_string()),
		     main, obj, obj.ActionArg0,
		     obj.ActionArg1, obj.ActionArg2)
   end
   return printMessage(main, obj, obj.Message)
end

function checkHightScore(lvl)
   local i = 0
   local lvl_check = 3
   local hs = phq.hightscores

   -- if quest done, skip
   if (yeGetInt(ygGet("phq.quests.hightscores.lvl"))) > 1 then
      return 0
   end

   if (yeGetInt(ygGet("phq.quests.hightscores.lvl"))) > 0 then
      if (yeGetInt(lvl) == 0) then
	 return 0
      end
      lvl_check = 1
   end

   -- foreach game highscore in 'Arcade_score.json', check first 3 levels
   while i < lvl_check do
      local j = 0
      while j < yeLen(hs) do
	 if phq.pj.name:to_string() == yeGetKeyAt(hs[j], i) then
	    phq.quests.hightscores = {}
	    if lvl_check == 1 then
	       phq.quests.hightscores.lvl = 2
	    else
	       phq.quests.hightscores.lvl = 1
	    end
	    return 1
	 end
	 j = j + 1
      end
      i = i + 1
   end
   return 0
end

function showHightScore(wid, score)
   wid = Entity.wrapp(wid)
   if score == nil then
      score = yeGetInt(ygGet(wid.score_path:to_string()))
   else
      score = yLovePtrToNumber(score)
   end
   local hs = ygGet(wid.hightscore_path:to_string())
   local hgw = Entity.new_array()
   local str = Entity.new_string("")
   local main = Entity.wrapp(ywCntWidgetFather(wid))
   local name = phq.pj.name:to_string()
   local c_score = yeGet(hs, name)

   if c_score and yeGetInt(c_score) < score then
      yHightScorePush(hs, name, score)
   end
   yHightScoreString(hs, str)
   backToGame(wid)
   hgw["<type>"] = "text-screen"
   hgw["text-align"] = "center"
   hgw.text = str
   hgw.background = "rgba: 155 155 255 190"
   hgw.action = Entity.new_func(backToGameOnEnter)
   ywPushNewWidget(main, hgw)
   return YEVE_ACTION
end

function playSnake(wid, _eve, version)
   wid = Entity.wrapp(wid)
   local main

   if wid.isDialogue then
      wid = Entity.wrapp(yDialogueGetMain(wid))
   end
   main = Entity.wrapp(ywCntWidgetFather(wid))

   version = yeGetInt(version)
   ywCntPopLastEntry(main)
   local snake = Entity.new_array()

   snake["<type>"] = "snake"
   snake.dreadful_die = 1
   snake.hitWall = "snake:snakeWarp"
   if version > 0 then
      snake.hightscore_path = "phq.hightscores.snake"
      snake.score_path = "snake.score"
      snake.die = Entity.new_func(showHightScore)
      snake.quit = Entity.new_func(showHightScore)
      snake.nb_layers = 2
      snake.resources = File.jsonToEnt("snake/resources.json")
      snake.eat = ygGet("snake.showScore")
   else
      snake.die = Entity.new_func("backToGame")
      snake.quit = Entity.new_func("backToGame")
      snake.resources = "snake:resources"
   end
   snake.background = "rgba: 255 255 255 255"
   snake.oldTimer = main["turn-length"]
   main["turn-length"] = 200000
   ywPushNewWidget(main, snake)
   if version > 0 then
      local tx = Entity.new_array(snake, "score_wid")

      tx["<type>"] = "text-screen"
      tx.text = "score: 0"
      ywPushNewWidget(main, tx)
   end
   main.current = 2
end

local function back_and_reload_mc()
   lpcs.handlerReload(yeGet(main_widget, "pj"))
   backToGame2()
end

function open_dressup_menu()
   local wid = Entity.new_array()

   print("open_dressup_menu !!!!!!")
   wid["<type>"] = "dressup"

   wid.background = "rgba: 140 150 155 255";
   wid.char_clothes = phq.pj.inventory;
   wid.quit = Entity.new_func(back_and_reload_mc)
   wid.character = phq.pj

   ywPushNewWidget(main_widget, wid)
   return YEVE_ACTION
end

function push_npc(pos, name, dir, npc)
   -- let's say that for now on, we can pass the npc directly to this function
   if npc == nil then
      npc = npcs[name]
   end
   local c = main_widget.mainScreen
   local npch = nil

   if yIsNil(npc.is_generic) then
      npch = yeGet(main_widget.npcs, name)
   end

   if yIsNNil(npch) then
      npc = npch
   elseif yeGetString(npc.type) == "sprite" then
      npc = sprite_man.createHandler(npc, c, main_widget.npcs, name)
      npc = Entity.wrapp(npc)
      generic_handlerRefresh(npc)
   else
      dressup.dressUp(npc)
      npc = lpcs.createCaracterHandler(npc, c, main_widget.npcs, name)
   end

   npc = Entity.wrapp(npc)
   generic_setPos(npc, pos.ent)
   generic_setDir(npc, dir)
   generic_handlerRefresh(npc)
   npc.canvas.Collision = 1
   return npc
end

function tacticalFight(_wid, _eve, args)
   TACTICAL_FIGHT_MODE = MODE_TACTICAL_FIGHT_INIT
   main_widget.tactical = {}
   main_widget.tactical.args = args
   if phq_only_fight > 0 then
      phq_only_fight = 0
      backToGame2()
      phq_only_fight = 1
   end
end

function changeScene(_wid, _eve, scene, entry)
   if type(entry) ~= "number" then
      entry = yeGetInt(entry)
   end

   if type(scene) ~= "string" then
      scene = yeGetString(scene)
   end

   load_scene(main_widget, scene, entry)
   backToGame2()
end

function gotoJail(wid)
   load_scene(main_widget, "police", 1)
   ygSetInt("phq.events.in_jail", 1)
   backToGame(wid)
   ygIncreaseInt("phq.pj.reputation.bully", 1)
   printMessage(main_widget, nil,
		"you go to jail you don't touch anything and\nmake no joke about board game")
end

function playAstShoot(wid)
   wid = Entity.wrapp(wid)
   local main

   if wid.isDialogue then
      wid = Entity.wrapp(yDialogueGetMain(wid))
   end
   main = Entity.wrapp(ywCntWidgetFather(wid))

   ywCntPopLastEntry(main)
   local ast_shoot = Entity.new_array()

   ast_shoot["<type>"] = "asteroide-shooter"
   ast_shoot.hightscore_path = "phq.hightscores.ast-shoot"
   ast_shoot.die = Entity.new_func(showHightScore)
   ast_shoot.quit = Entity.new_func("backToGame")
   ast_shoot.oldTimer = main["turn-length"]
   main["turn-length"] = 40000
   ywPushNewWidget(main, ast_shoot)
   return YEVE_ACTION
end

function playTetris(wid)
   wid = Entity.wrapp(wid)
   local main

   if wid.isDialogue then
      wid = Entity.wrapp(yDialogueGetMain(wid))
   end
   main = Entity.wrapp(ywCntWidgetFather(wid))

   ywCntPopLastEntry(main)
   local t = Entity.new_array()

   t["<type>"] = "tetris-ascii"
   t.die = Entity.new_func("backToGame")
   t.quit = Entity.new_func("backToGame")
   ywPushNewWidget(main, t)
   return YEVE_ACTION
end

function phs_start(_wid)
   local m = main_widget

   local t = Entity.new_array()
   t["<type>"] = "phs"
   t.resources = ygGet("phs.resources")
   ywPushNewWidget(m, t)
   return YEVE_ACTION
end

function ascii_end(wid)
   phq.env.have_win_ascii2 = yeGetIntAt(wid, "have_win")
   backToGame(wid)
end

function dream_z_shooter_xp(wid)
   wid = Entity.wrapp(wid)
   local xp = yeGetInt(wid.score) / 10 + 1
   backToGame2()
   increaseStat(main_widget, phq.pj, "xp", xp)
end

function play(_wid, eve, game, timer, end_f_str, keep_dialogue)
   local main = main_widget

   print("play !!!!", eve, game, yeGetInt(timer), end_f_str, yeGetString(end_f_str),
	 " - ", yeLen(main.entries))

   -- kind of weird, but as I don't use backToGame here, when
   -- call from dialog (as generally use) current is 2, and play widget replace it
   -- if call from sleep (or nor dialogue), we need to force current
   if main.current < 2 then
      main.current = 2
   elseif yeGetInt(keep_dialogue) < 1 then
      ywCntPopLastEntry(main)
   end
   local t = Entity.new_array()

   t["<type>"] = game
   t["parent-rect"] = main_widget['wid-pix'];
   if yIsNNil(end_f_str) then
      t.die = Entity.new_func(yeGetString(end_f_str))
      t.win = Entity.new_func(yeGetString(end_f_str))
      t.lose = Entity.new_func(yeGetString(end_f_str))
      t.quit = Entity.new_func(yeGetString(end_f_str))
   else
      t.win = Entity.new_func("backToGame")
      t.die = Entity.new_func("backToGame")
      t.lose = Entity.new_func("backToGame")
      t.quit = Entity.new_func("backToGame")
   end
   t.oldTimer = main["turn-length"]
   if yIsNNil(timer) then
      main["turn-length"] = timer
   end
   ywPushNewWidget(main, t)
   return YEVE_ACTION
end

function playVapp(_wid)
   main = main_widget

   ywCntPopLastEntry(main)
   local vapp = Entity.new_array()

   vapp["<type>"] = "vapz"
   vapp.resources = "vapp:resources.map"
   vapp.die = Entity.new_func(showHightScore)
   vapp.quit = Entity.new_func("backToGame")
   vapp.hightscore_path = "phq.hightscores.vapp"
   vapp.oldTimer = main["turn-length"]
   main["turn-length"] = 150000
   ywPushNewWidget(main, vapp)
   return YEVE_ACTION
end

function push_dream(_unused_wid, _unused_eves, dream)
   if yIsNil(phq.env.dreams) then
      phq.env.dreams = {}
   end
   yePushBack(phq.env.dreams, dream)
end

function doSleep(ent, upCanvas)
   ywCanvasRemoveObj(upCanvas.ent, ent.sleep_r)

   if sleep_time > 200 then
      ent.sleep = nil
      sleep_time = 0
      return true
   end

   local cam = main_widget_screen.cam
   local x0 = ywPosX(cam)
   local y0 = ywPosY(cam)
   local sl = main_widget.sleep_loc

   if (ywidTurnTimer() < 10000) then
      yuiUsleep(10000)
   end
   if sleep_time == 100 then
      if yIsNNil(sl) then
	 local slp = main_widget.sleep_loc_pos

	 changeScene(main_widget, nil, sl, Entity.new_int(0))
	 if yIsNNil(slp) then
	    ylpcsHandlerSetPos(main_widget.pj, slp)
	    reposeCam(main_widget, main_widget.pj)
	 end
	 main_widget.sleep_loc = nil
	 main_widget.sleep_loc_pos = nil
      else
	 pj_pos = ylpcsHandePos(main_widget.pj)
	 yeIncrRef(pj_pos)
	 load_scene(main_widget, main_widget.cur_scene_str:to_string(), -1, pj_pos)
	 yeDestroy(pj_pos)
      end
   elseif sleep_time == 50 then
      if yIsNNil(phq.env.dreams) then
	 print("loop over dreams")
	 local dreams = phq.env.dreams
	 for i = 0, yeLen(dreams) - 1 do
	    print("Action on:", dreams[i])
	    if yIsNNil(dreams[i]) then
	       ywidActions(main_widget, dreams[i],  nil)
	       dreams[i] = nil
	    end
	 end
      end
   end

   if sleep_time < 100 then

      local str = "rgba: 0 0 0 ".. math.floor(255 * sleep_time / 100)
      ent.sleep_r = upCanvas:new_rect(x0, y0, str,
				      Pos.new(window_width,
					      window_height).ent).ent
   else
      local st = sleep_time - 100
      local str = "rgba: 0 0 0 ".. math.floor(255 - 255 * st / 100)
      ent.sleep_r = upCanvas:new_rect(x0, y0, str,
				      Pos.new(window_width,
					      window_height).ent).ent
   end
   sleep_time = sleep_time + 2
   return false
end
