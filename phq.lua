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

tiled = Entity.wrapp(ygGet("tiled"))
local jrpg_fight = Entity.wrapp(ygGet("jrpg-fight"))
local dialogue_box = Entity.wrapp(ygGet("DialogueBox"))
lpcs = Entity.wrapp(ygGet("lpcs"))
sprite_man = Entity.wrapp(ygGet("sprite-man"))
phq = Entity.wrapp(ygGet("phq"))
dressup = Entity.wrapp(ygGet("dressup"))
local modPath = Entity.wrapp(ygGet("phq.$path")):to_string()
npcs = nil
scenes = Entity.wrapp(ygGet("phq.scenes"))
saved_scenes = nil
dialogues = Entity.new_array()
o_dialogues = nil

quests_info = File.jsonToEnt("quests/main.json")

main_widget = nil

local run_script = nil

window_width = 800
window_height = 600

phq_only_fight = 0
phq_turn_cnt = 0

-- set as global so can be use by ai
pix_mv = 0
pix_floor_left = 0
local PIX_MV_PER_MS = 5
local TURN_LENGTH = Y_REQUEST_ANIMATION_FRAME

NO_COLISION = 0
NORMAL_COLISION = 1
CHANGE_SCENE_COLISION = 2
FIGHT_COLISION = 3
local PHQ_SUP = 0
local PHQ_INF = 1


LPCS_LEFT = ygGetInt("lpcs.LEFT")
LPCS_DOWN = ygGetInt("lpcs.DOWN")
LPCS_RIGHT = ygGetInt("lpcs.RIGHT")
LPCS_UP = ygGetInt("lpcs.UP")

DAY_STR = {"monday", "tuesday", "wensday", "thursday",
	   "friday", "saturday", "sunday"}


local newly_loaded = true
local upKeys = Event.CreateGrp(Y_UP_KEY, Y_W_KEY)
local downKeys = Event.CreateGrp(Y_DOWN_KEY, Y_S_KEY)
local leftKeys = Event.CreateGrp(Y_LEFT_KEY, Y_A_KEY)
local rightKeys = Event.CreateGrp(Y_RIGHT_KEY, Y_D_KEY)
local actionKeys = Event.CreateGrp(Y_SPACE_KEY, Y_ENTER_KEY)

local AGRESIVE_TALKER = 2
local AGRESIVE_ATTACKER = 1
local NOT_AGRESIVE = 0

function distanceToDir(x, y)
   if math.abs(x) > math.abs(y) then
      if x > 0 then
	 return LPCS_RIGHT
      else
	 return LPCS_LEFT
      end
   else
      if y > 0 then
	 return LPCS_DOWN
      else
	 return LPCS_UP
      end
   end
end

function lpcsStrToDir(sdir)
   if sdir == "left" then
      return LPCS_LEFT
   elseif sdir == "right" then
      return LPCS_RIGHT
   elseif sdir == "down" then
      return LPCS_DOWN
   end
   return LPCS_UP
end

function lpcsDirToStr(sdir)
   if sdir == LPCS_LEFT then
      return "left"
   elseif sdir == LPCS_RIGHT then
      return "right"
   elseif sdir == LPCS_DOWN then
      return "down"
   elseif sdir == LPCS_UP then
      return "up"
   end
   return "unknow"
end

function generic_handlerRmCanva(npc)
   if yeGetString(npc.char.type) == "sprite" then
      sprite_man.handlerRemoveCanva(npc)
   else
      lpcs.handlerRemoveCanva(npc)
   end
end

function generic_handlerRefresh(npc)
   if yeGetString(npc.char.type) == "sprite" then
      sprite_man.handlerRefresh(npc)
   else
      lpcs.handlerRefresh(npc)
   end
end

function generic_handlerNullify(npc)
   if yeGetString(npc.char.type) == "sprite" then
      sprite_man.handlerNullify(npc)
   else
      lpcs.handlerNullify(npc)
   end
end

function generic_handlerPos(npc)
   if yIsNil(npc) or npc.char == nil then
      return
   end
   if yeGetString(npc.char.type) == "sprite" then
      return sprite_man.handlerPos(npc)
   else
      return ylpcsHandlerPos(npc)
   end
end

function generic_handlerSize(npc)
   if yIsNil(npc) or npc.char == nil then
      return
   end
   if yeGetString(npc.char.type) == "sprite" then
      return sprite_man.handlerSize(npc)
   else
      return ylpcsHandlerSize(npc)
   end
end

function generic_setDir(npc, dir)
   if yeGetString(npc.char.type) == "sprite" then
      dir = yeGetInt(dir)
      if yeGetString(npc.sp.disposition) == "uldr" then
	 if dir == LPCS_LEFT then
	    yeSetAt(npc, "y_offset", 32)
	 elseif dir == LPCS_RIGHT then
	    yeSetAt(npc, "y_offset", 96)
	 elseif dir == LPCS_DOWN then
	    yeSetAt(npc, "y_offset", 64)
	 else
	    yeSetAt(npc, "y_offset", 0)
	 end
      elseif yeGetString(npc.sp.disposition) == "urdl" then
	 if dir == LPCS_LEFT then
	    yeSetAt(npc, "y_offset", 96)
	 elseif dir == LPCS_RIGHT then
	    yeSetAt(npc, "y_offset", 32)
	 elseif dir == LPCS_DOWN then
	    yeSetAt(npc, "y_offset", 64)
	 else
	    yeSetAt(npc, "y_offset", 0)
	 end
      else
	 if dir == LPCS_LEFT then
	    yeSetAt(npc, "y_offset", 32)
	 elseif dir == LPCS_RIGHT then
	    yeSetAt(npc, "y_offset", 64)
	 elseif dir == LPCS_UP then
	    yeSetAt(npc, "y_offset", 96)
	 else
	    yeSetAt(npc, "y_offset", 0)
	 end
      end
   else
      lpcs.handlerSetOrigXY(npc, 0, dir)
      generic_handlerRefresh(npc)
   end
end

function generic_setPos(npc, pos)
   if yeGetString(npc.char.type) == "sprite" then
      sprite_man.handlerSetPos(npc, pos)
   else
      ylpcsHandlerSetPos(npc, pos)
   end
end

function generic_handlerMove(npc, add)
   ywPosAdd(generic_handlerPos(npc), add)
end

function generic_handlerMoveXY(npc, x, y)
   ywPosAddXY(generic_handlerPos(npc), x, y)
end

local function reposScreenInfo(ent, x0, y0)
   ywCanvasObjSetPos(ent.night_r, x0, y0)
   dialogue_box.set_pos(ent.box, 40 + x0, 40 + y0)
   for i = 0, yeLen(ent.rain_a) - 1 do
      local r = ent.rain_a[i]
      local x = yuiRand() % window_width
      local y = yuiRand() % window_height

      ywCanvasObjSetPos(r, x + x0, y + y0)
   end
end

function reposeCam(main, dst_char, xadd, yadd)
   local canvas = main.mainScreen
   local upCanvas = main.upCanvas
   local offset = main.cam_offset
   local pjPos = Pos.wrapp(ylpcsHandePos(dst_char))
   local x0 = pjPos:x() - window_width / 2
   local y0 = pjPos:y() - window_height / 2

   if yIsNNil(offset) then
      x0 = x0 + ywPosX(offset)
      y0 = y0 + ywPosY(offset)
   end

   if yIsNNil(xadd) then
      x0 = x0 + xadd
   end
   if yIsNNil(yadd) then
      y0 = y0 + yadd
   end
   ywPosSet(canvas.cam, x0, y0)
   ywPosSet(upCanvas.cam, x0, y0)
   reposScreenInfo(main, x0, y0)
end

function checkObjTime(obj, cur_time)
   local obj_time = obj.Time

   if main_widget.no_chktime_t > 0 then
      return false
   end
   if yeGetInt(obj.disable_timer) and
   os.time() - yeGetInt(obj.disable_timer) < 2 then
      return false
   end
   if obj_time then
      local str_t = obj_time:to_string()
      if (string.sub(str_t, 1, 1) == "!") then
	 str_t =  string.sub(str_t, 2)
	 if string.lower(str_t) == string.lower(cur_time) then
	    return false
	 end
	 return true
      end
      if yeStrCaseCmp(obj_time, cur_time) ~= 0 then
	 return false
      end
   end
   return true
end

function checkNpcPresence(obj, npc, scene, is_ai_point)
   if npc == nil then
      return false
   end

   local pp = yeGetIntAt(obj, "Presence %")
   if pp > 0 and yuiRand() % 99 > pp then
      return false
   end
   if yeGetIntAt(obj, "dead") == 1 then
      return false
   end
   local cur_time = phq.env.time:to_string()

   if checkObjTime(obj, cur_time) == false then
      return false
   end

   local c_place = yeGetString(npc._place)
   if yIsNNil(c_place) and c_place ~= scene then
      return false
   end

   if npc.out_time and
      is_ai_point == false and
      yeGetInt(npc.out_time.day) == phq.env.day:to_int() and
      yeGetInt(npc.out_time.week) == phq.env.week:to_int() and
   yeGetString(npc.out_time.time) == phq.env.time:to_string() then
      return false
   end

   if npc.calendar then
      local day_calenday = npc.calendar[DAY_STR[phq.env.day:to_int() + 1]]
      if day_calenday == nil then
	 day_calenday = npc.calendar.everyday
      end
      if yeType(day_calenday) == YSTRING then
	 return yeGetString(day_calenday) == scene
      elseif day_calenday ~= nil then
	 return yeGetString(day_calenday[cur_time]) == scene
      end
      return false
   end

   local nname = yeGetString(npc.name)
   if is_npc_ally(phq.pj, nname) then
      return false
   end

   if yIsNNil(npc.location) then
      if npc.location:to_string() == scene then
	 return true
      else
	 return false
      end
   end
   return true
end

local function _include(target, file)
   local includes = file._include
   local i = 0

   while i < yeLen(includes) do
      local inc = includes[i]
      inc = File.jsonToEnt(inc:to_string())
      _include(target, inc)
      local j = 0
      while j < yeLen(inc) do
	 yePushBack(target, yeGet(inc, j), yeGetKeyAt(inc, j));
	 j = j + 1
      end
      i = i + 1
   end
   file._include = nil
end

function init_phq(mod)
   Widget.new_subtype("phq", "create_phq")
   Widget.new_subtype("phq-new-game", "create_new_game")

   mod = Entity.wrapp(mod)
   mod.actioned = {}
   mod.checkHightScore = Entity.new_func("checkHightScore")
   mod.backToGame = Entity.new_func("backToGame")
   mod.StartFight = Entity.new_func("StartFight")
   mod.DrinkBeer = Entity.new_func("DrinkBeer")
   mod.openStore = Entity.new_func("openStore")
   mod.go_under = Entity.new_func(go_under)
   mod.GetDrink = Entity.new_func("GetDrink")
   mod.continue = Entity.new_func("continue")
   mod.load_slot = Entity.new_func("load_slot")
   mod.newGame = Entity.new_func("newGame")
   mod.printMessage = Entity.new_func("printMessage")
   mod.sleep = Entity.new_func("sleep")
   mod.actionOrPrint = Entity.new_func("actionOrPrint")
   mod.startDialogue = Entity.new_func("startDialogue")
   mod.playSnake = Entity.new_func("playSnake")
   mod.playTetris = Entity.new_func("playTetris")
   mod.playAstShoot = Entity.new_func("playAstShoot")
   mod.playVapp = Entity.new_func("playVapp")
   mod.play = Entity.new_func("play")
   mod.pay = Entity.new_func("pay")
   mod.phs_start = Entity.new_func("phs_start")
   mod.takeObject = Entity.new_func("takeObject")
   mod.PjLeave = Entity.new_func("PjLeave")
   mod.vnScene = Entity.new_func("vnScene")
   mod.increase = Entity.new_func("increase")
   mod.tmp_increase = Entity.new_func("tmp_increase")
   mod.recive = Entity.new_func("recive")
   mod.remove = Entity.new_func("remove")
   mod.quest_script = Entity.new_func("call_quest_script")
   mod.use_time_point = Entity.new_func("use_time_point")
   mod.changeScene = Entity.new_func("changeScene")
   mod.gotoJail = Entity.new_func("gotoJail")
   -- this one is simpler to use
   mod.openGLobalMenu = Entity.new_func("openGlobalMenu")
   -- this one take "main", idx, and a arg in parametter
   mod.openGlobMenu = Entity.new_func("openGlobMenu")
   mod.setCurStation = Entity.new_func("setCurStation")
   mod.join_team = Entity.new_func("join_team")
   mod.leave_team = Entity.new_func("leave_team_callback")
   mod.ai_point_remove = Entity.new_func(ai_point_remove)
   mod.chk_affection = Entity.new_func(chk_affection)
   mod.advance_time = Entity.new_func(advance_time)
   mod.tacticalFight = Entity.new_func(tacticalFight)
   mod.push_dream = Entity.new_func(push_dream)
   mod.DressUp = {}
   mod.DressUp.Menu = Entity.new_func(open_dressup_menu)
   mod.misc_fnc = {}
   mod.misc_fnc.class_even = Entity.new_func(calsses_event_dialog_gen)
   mod.misc_fnc.read_temps_des_escargots = Entity.new_func(rd_tps_ds_escgt)
   mod.misc_fnc.save_fight_mode = Entity.new_func("save_fight_mode")
   mod.misc_fnc.load_fight_mode = Entity.new_func("load_fight_mode")
   mod.triggers = {}
   mod.triggers.block_message = Entity.new_func(trigger_block_message)
end



function load_game(save_dir)
   local game = ygGet("phq:menus.game")
   game = Entity.wrapp(game)
   game.saved_dir = save_dir
   game.saved_data = ylaFileToEnt(YJSON, save_dir.."/misc.json")
   local pj = ylaFileToEnt(YJSON, save_dir.."/pj.json")
   phq.pj = pj
   local env = ylaFileToEnt(YJSON, save_dir.."/env.json")
   game.saved_data.pj_pos = ygFileToEnt(YJSON, save_dir.."/pj-pos.json")
   saved_scenes = Entity._wrapp_(ygFileToEnt(YJSON,
					       save_dir.."/saved-scenes.json"),
				   true)
   phq.env = env
   phq.hightscores = File.jsonToEnt(save_dir.."/Arcade_score.json")
   local actioned = File.jsonToEnt(save_dir.."/actioned.json")
   if yeType(actioned) == YARRAY then
      phq.actioned = actioned
   end
   local quests = File.jsonToEnt(save_dir.."/quests.json")
   if yeType(quests) == YARRAY then
      phq.quests = quests
   end
   local events = File.jsonToEnt(save_dir.."/evenements.json")
   phq.events = events
   local loaded_npcs = File.jsonToEnt(save_dir.."/npcs.json")
   local npcs = File.jsonToEnt("npcs.json")
   _include(npcs, npcs)
   local p = yePatchCreate(npcs, loaded_npcs)
   yePatchAplyExt(npcs, p, YE_PATCH_NO_SUP)
   phq.npcs = npcs
   local allies = phq.pj.allies
   for i = 0, yeLen(allies) do
      local k = yeGetKeyAt(allies, i)
      local npc = npcs[k]

      yeAttach(allies, npcs[k], i, k, 0)
   end
   phq_only_fight = yeGetInt(phq.env.phq_only_fight)
   ywidNext(ygGet("phq:menus.game"))
   --yCallNextWidget(entity);
end

function continue(entity)
   return load_game(ygUserDir() .. "saved/cur")
end

function load_fight_mode(entity)
   print("load_fight_mode !!!!")
   return load_game(ygUserDir() .. "saved/fight_mode")
end

function mnLoadSlot(mn)
   local slot = Entity.wrapp(ywMenuGetCurrentEntry(mn)).s:to_string()

   print("LOAD slot: ", ygUserDir() .. slot)
   return load_game(ygUserDir() .. slot)
end

function load_slot(entity)
   local m = Menu.new_entity()
   local slots = {0, 1, 2, 3, 4, 5, 6, 7 ,8, 9, 'A', 'B', 'C', 'E', 'F', 10}

   Entity.wrapp(ywMenuGetCurrentEntry(entity)).next = m
   m.ent.background = "rgba: 255 255 255 255"
   m.ent.next = entity
   m.ent["text-align"] = "center"
   m:push("back", "callNext")
   for k,slot in pairs(slots) do
      if yuiFileExist(ygUserDir() .. "/saved/slot_" .. slot) == 0 then
	 local e = m:push("slot " .. slot, Entity.new_func("mnLoadSlot"))
	 e.s = "saved/slot_" .. slot
      end
   end

   -- goto new menu
   -- make load menu
   -- put next new menu as current menu (for back)
   ywidNext(m.ent, entity)
   --return load_game(entity, "./saved/cur")
end

function saveCurDialogue(main)
   saved_scenes[main.cur_scene_str:to_string()] = {}
   saved_scenes[main.cur_scene_str:to_string()].o = main.mainScreen.objects
   local p = ylaPatchCreate(o_dialogues, dialogues)
   saved_scenes[main.cur_scene_str:to_string()].d = Entity.wrapp(p)
end

function saveGame(main, saveDir)
   local destDir = ygUserDir() .. "./saved/" .. saveDir
   local misc = Entity.new_array()

   yuiMkdir(ygUserDir() .. "./saved")
   yuiMkdir(destDir)
   misc.cur_scene_str = main.cur_scene_str
   saveCurDialogue(main)
   ygEntToFile(YJSON, destDir .. "/pj-pos.json", ylpcsHandePos(main.pj))
   ygEntToFile(YJSON, destDir .. "/pj.json", phq.pj)
   ygEntToFile(YJSON, destDir .. "/evenements.json", phq.events)
   ygEntToFile(YJSON, destDir .. "/misc.json", misc)
   ygEntToFile(YJSON, destDir .. "/env.json", phq.env)
   ygEntToFile(YJSON, destDir .. "/saved-scenes.json", saved_scenes)
   ygEntToFile(YJSON, destDir .. "/Arcade_score.json", phq.hightscores)
   ygEntToFile(YJSON, destDir .. "/actioned.json", phq.actioned)
   ygEntToFile(YJSON, destDir .. "/quests.json", phq.quests)
   ygEntToFile(YJSON, destDir .. "/npcs.json", npcs)
   print("save in: " .. destDir)
end

function save_fight_mode()
   phq.env.phq_only_fight = 1
   saveGame(main_widget, "fight_mode")
end

function saveGameCallback(wid)
   wid = Entity.wrapp(wid)
   if yeGetInt(wid.in_subcontained) == 1 then
      wid = ywCntWidgetFather(wid)
   end
   saveGame(Entity.wrapp(ywCntWidgetFather(wid)), "cur")
   printMessage(main_widget, nil, "Quick Save Done")
end

function checkTiledCondition(actionable)
   local conditionOp = actionable.Condition

   if conditionOp == nil then
      return true
   end
   local condition = Entity.new_array()
   yeCreateString(yeGetString(conditionOp), condition);
   yePushBack(condition, yeGet(actionable, "ConditionArg0"));
   yePushBack(condition, yeGet(actionable, "ConditionArg1"));
   local ret = yeCheckCondition(condition);
   return ret
end

function CheckColisionTryChangeScene(main, cur_scene, direction)
   if cur_scene.out and cur_scene.out[direction] then
      local dir_info = cur_scene.out[direction]
      local nextSceneTxt = nil
      if dir_info.to then
	 nextSceneTxt = yeGetString(yeToLower(dir_info.to))
      else
	 nextSceneTxt = yeGetString(yeToLower(dir_info))
      end
      load_scene(main, nextSceneTxt, yeGetIntAt(dir_info, "entry"))
      return true
   end
   return false
end

local this_door_is_lock_msg = 0

local function exit_trigger_check(exit, colRect, cur_time)
   if checkTiledCondition(exit) == false then
      return NO_COLISION
   end

   local rect = exit.rect
   if ywRectCollision(rect, colRect) then
      if checkObjTime(exit, cur_time) then
	 local nextSceneTxt = yeGetString(yeToLower(exit.nextScene))
	 if yIsNil(nextSceneTxt) == false then
	    load_scene(main_widget, nextSceneTxt, yeGetInt(exit.entry))
	 else
	    phq_do_action(main_widget, exit)
	    if yIsNil(exit.no_disable_timer) then
	       exit.disable_timer = os.time()
	    end
	    if exit.colision_ret and exit.colision_ret > 0 then
	       return exit.colision_ret:to_int()
	    end
	 end
	 return CHANGE_SCENE_COLISION
      elseif yeGetInt(exit.disable_timer) == 0 then
	 local TIME_RESET = 1000000

	 if this_door_is_lock_msg < 1 then
	    this_door_is_lock_msg = TIME_RESET
	    printMessage(main_widget, nil, "It's close !")
	 else
	    print(this_door_is_lock_msg)
	    this_door_is_lock_msg = this_door_is_lock_msg - ywidGetTurnTimer()
	 end
      end
   end
   return NO_COLISION
end

function CheckColision(main, canvasWid, pj)
   local pjPos = ylpcsHandePos(pj)
   local colRect = Rect.new(ywPosX(pjPos) + 10, ywPosY(pjPos) + 30, 20, 20).ent
   local exites = main.exits
   local triggers = main.triggers
   local cur_time = phq.env.time:to_string()

   for i = 0, yeLen(triggers) - 1 do
      local ret = exit_trigger_check(triggers[i], colRect, cur_time)

      if ret ~= NO_COLISION then return ret end
   end

   for i = 0, yeLen(exites) - 1 do
      local ret = exit_trigger_check(exites[i], colRect, cur_time)

      if ret ~= NO_COLISION then return ret end
   end

   local cur_scene = main.cur_scene
   if ywPosX(pjPos) < 0 then
      if CheckColisionTryChangeScene(main, cur_scene, "left") then
	 return CHANGE_SCENE_COLISION
      else
	 return NORMAL_COLISION
      end
   elseif ywPosY(pjPos) + 30 < 0 then
      if CheckColisionTryChangeScene(main, cur_scene, "up") then
	 return CHANGE_SCENE_COLISION
      else
	 return NORMAL_COLISION
      end
   elseif ywPosX(pjPos) + lpcs.w_sprite > canvasWid["tiled-wpix"]:to_int() then
      if CheckColisionTryChangeScene(main, cur_scene, "right") then
	 return CHANGE_SCENE_COLISION
      else
	 return NORMAL_COLISION
      end
   elseif ywPosY(pjPos) + lpcs.h_sprite > canvasWid["tiled-hpix"]:to_int() then
      if CheckColisionTryChangeScene(main, cur_scene, "down") then
	 return CHANGE_SCENE_COLISION
      else
	 return NORMAL_COLISION
      end
   end

   local col = ylaCanvasCollisionsArrayWithRectangle(canvasWid, colRect)

   col = Entity.wrapp(col)
   i = 0
   while i < yeLen(col) do
      local obj = col[i]

      if yeGetIntAt(obj, "Collision") == 1 and
      ywCanvasCheckColisionsRectObj(colRect, obj) then
	 local agresivity = yeGetIntAt(obj, "agresive")

	 if agresivity > 0 then
	    if agresivity == AGRESIVE_ATTACKER then
	       return FIGHT_COLISION, obj
	    elseif agresivity == AGRESIVE_TALKER then
	       local dialogue = obj.dialogue

	       startDialogue(main_widget, obj, dialogue)
	       obj.agresive = NOT_AGRESIVE
	       yeRemoveChild(main_widget.enemies,
			     npc_handler_from_canva(obj))
	       return YEVE_ACTION
	    end
	 end
	 return NORMAL_COLISION, nil
      end
      i = i + 1
   end
   return NO_COLISION, nil
end

function pushMainMenu(main)
   local mn = Menu.new_entity()

   fillMiscMenu(mn.ent)
   mn.ent.onEsc = Entity.new_func("gmGetBackFocus")
   mn.ent.next = Entity.wrapp(ywCntWidgetFather(main)).next
   mn.ent.next_target = "main"
   ywPushNewWidget(main, mn.ent)
end

function phq_do_action(main, a)
   local args = { a.Arg0, a.Arg1, a.Arg2, a.Arg3 }

   if yIsNil(a.Action) then
      print("no action in ", a)
      return
   end
   yesCall(ygGet(a.Action:to_string()), main:cent(), a:cent(), args[1],
	   args[2], args[3], args[4])

end

local should_track_mouse = false

function phq_action(entity, eve)
   collectgarbage("collect")
   if yeGetIntAt(entity, "current") > 1 then
      return NOTHANDLE
   end

   phq_turn_cnt = phq_turn_cnt + 1
   local turn_timer = ywidTurnTimer() / 10000
   entity = Entity.wrapp(entity)
   local st_hooks = entity.st_hooks
   local st_hooks_len = yeLen(entity.st_hooks)
   local dir_change = false
   local isNewlyLoad = newly_loaded

   newly_loaded = false
   entity.require_ret = 0
   --print("Last Turn Length: ", turn_timer, ywidTurnTimer())
   if isNewlyLoad then
      turn_timer = 1
   end
   local i = 0
   while i < st_hooks_len do
      local st_hook = st_hooks[i]
      local stat_name = yeGetKeyAt(st_hooks, i)
      local stat = phq.pj[stat_name]

      if stat then
	 local cmp_t = st_hook.comp_type
	 if (cmp_t:to_int() == 0 and stat > st_hook.val) or
	 (cmp_t:to_int() == 1 and stat < st_hook.val) then
	    print(yeGetKeyAt(st_hooks, i),
		  st_hook.val, st_hook.comp_type)
	    st_hook.hook(ent)
	 end
      end
      i = i + 1
   end

   if entity.no_chktime_t > 0 then
      entity.no_chktime_t = entity.no_chktime_t - ywidGetTurnTimer()
   elseif entity.no_chktime_t < 0 then
      entity.no_chktime_t = 0
   end

   if entity.box_t then
      if entity.box_t < 0 then
	 dialogue_box.rm(entity.upCanvas, entity.box)
	 entity.box = nil
	 entity.box_t = 0
      elseif isNewlyLoad == false then
	    entity.box_t = entity.box_t - ywidGetTurnTimer()
      end
   end

   if TACTICAL_FIGHT_MODE ~= MODE_NO_TACTICAL_FIGHT then
      return do_tactical_fight(eve)
   end

   if entity.sleep then
      if doSleep(entity, Canvas.wrapp(entity.upCanvas)) == false then
	 return YEVE_ACTION
      end
   end

   tmpObjsRemover(entity)

   -- I might make school_events a more generic array
   local action_eve = yeFirst(school_events)
   if yIsNNil(action_eve) then
      local ret = ywidAction(action_eve, wid, nil)
      if ret == BLOCK_EVE_NO_UNSET then
	 return 0
      end
      yeUnsetFirst(school_events)
      return ret
   end

   local is_upkey_up = yevIsGrpUp(eve, upKeys)
   local is_downkey_up = yevIsGrpUp(eve, downKeys)
   local is_leftkey_up = yevIsGrpUp(eve, leftKeys)
   local is_rightkey_up = yevIsGrpUp(eve, rightKeys)


   if yevMouseDown(eve) then
      should_track_mouse = true
   end

   if yevMouseUp(eve) then
      should_track_mouse = false
      is_rightkey_up = true
      is_leftkey_up = true
      is_downkey_up = true
      is_upkey_up = true
   end

   if should_track_mouse and yIsNNil(yevMousePos(eve)) then
      local mouse_pos = Entity.new_copy(yevMousePos(eve))
      local cam = entity.mainScreen.cam
      ywPosAdd(mouse_pos, cam)
      local pjpos = Entity.wrapp(ylpcsHandePos(entity.pj))
      local x_dist = ywPosX(mouse_pos) - ywPosX(pjpos);
      local y_dist = ywPosY(mouse_pos) - ywPosY(pjpos);
      local dist = math.sqrt(x_dist * x_dist + y_dist * y_dist)

      entity.pj.move.up_down = Entity.new_float(y_dist / dist)
      entity.pj.move.left_right = Entity.new_float(x_dist / dist)

      if (math.abs(y_dist / dist) > math.abs(x_dist / dist)) then
	 if y_dist > 0 then
	    entity.pj.y = LPCS_DOWN
	 else
	    entity.pj.y = LPCS_UP
	 end
      else
	 if x_dist > 0 then
	    entity.pj.y = LPCS_RIGHT
	 else
	    entity.pj.y = LPCS_LEFT
	 end
      end
      lpcs.handlerRefresh(main_widget.pj)

      --print("entity.print.move: ", entity.pj.move, x_dist / dist, y_dist / dist)
   end

   -- At firt it's here to test pushSmallTalk
   -- But why not keep it ?
   -- We could even use that latter to add easter egg
   if yevIsKeyDown(eve, Y_H_KEY) then
      local pjPos = Pos.wrapp(ylpcsHandePos(entity.pj))

      pushSmallTalk("Hello", pjPos:x(), pjPos:y())
   end

   if yevIsKeyDown(eve, Y_ESC_KEY) then
      return openGlobMenu(entity, GM_MISC_IDX)
   end

   if yevIsKeyDown(eve, Y_F_KEY) then
      StartFight(entity, eve, Entity.new_string("rat"))
   end

   if yevIsGrpDown(eve, upKeys) then
      entity.pj.move.up_down = Entity.new_float(-1)
      entity.pj.y = LPCS_UP
   elseif yevIsGrpDown(eve, downKeys) then
      entity.pj.move.up_down = Entity.new_float(1)
      entity.pj.y = LPCS_DOWN
   end

   if yevIsGrpDown(eve, leftKeys) then
      entity.pj.move.left_right = Entity.new_float(-1)
      entity.pj.y = LPCS_LEFT
   elseif yevIsGrpDown(eve, rightKeys) then
      entity.pj.move.left_right = Entity.new_float(1)
      entity.pj.y = LPCS_RIGHT
   end

   if yevIsKeyDown(eve, Y_C_KEY) then
      return openGlobMenu(entity, GM_STATS_IDX, true)
   elseif yevIsKeyDown(eve, Y_I_KEY) then
      return openGlobMenu(entity, GM_INV_IDX, true)
   elseif yevIsKeyDown(eve, Y_M_KEY) then
      return openGlobMenu(entity, GM_MAP_IDX, true)
   elseif yevIsKeyDown(eve, Y_J_KEY) then
      return openGlobMenu(entity, GM_QUEST_IDX)
   end

   if yevIsKeyDown(eve, Y_LSHIFT_KEY) then
      if (yeLen(main_widget.show_actionable) < 1) then
	 local e_actionables = entity.actionables
	 local e_exits = entity.exits
	 local show_act = entity.show_actionable
	 local i = 0

	 while  i < yeLen(e_actionables) do
	    local a = e_actionables[i]
	    local cr = a.rect

	    if (a.t and
		   a.t.d == phq.env.day and
		   a.t.t == phq.env.time and
		   a.t.w == phq.env.week)
	       or a.is_used
	    or checkTiledCondition(a) == false then
	       goto next_loop
	    end

	    show_act[i] = ywCanvasNewRectangle(entity.upCanvas,
					       ywRectX(cr), ywRectY(cr),
					       ywRectW(cr), ywRectH(cr),
					       "rgba: 250 250 127 127")
	    :: next_loop ::
	    i = i  + 1
	 end
	 local j = 0
	 while j < yeLen(e_exits) do
	    local cr = e_exits[j].rect
	    local w = ywRectW(cr)
	    local h = ywRectH(cr)

	    if w < 3 then w = 10 end
	    if h < 3 then h = 10 end
	    show_act[i] = ywCanvasNewRectangle(entity.upCanvas,
					       ywRectX(cr), ywRectY(cr),
					       w, h,
					       "rgba: 250 127 127 127")

	    j = j + 1
	    i = i  + 1
	 end
	 local cur_scene = entity.cur_scene
	 local canvasWid = entity.mainScreen
	 if cur_scene.out and cur_scene.out["left"] then
	    show_act[i] = ywCanvasNewRectangle(entity.upCanvas,
					       0, 0,
					       5, canvasWid["tiled-hpix"]:to_int(),
					       "rgba: 250 127 127 127")
	    i = i + 1
	 end
	 if cur_scene.out and cur_scene.out["right"] then
	    show_act[i] = ywCanvasNewRectangle(
	       entity.upCanvas,
	       canvasWid["tiled-wpix"]:to_int() - 10, 0,
	       5, canvasWid["tiled-hpix"]:to_int(),
	       "rgba: 250 127 127 127")
	    i = i + 1
	 end
	 if cur_scene.out and cur_scene.out["up"] then
	    show_act[i] = ywCanvasNewRectangle(
	       entity.upCanvas,
	       0, 0,
	       canvasWid["tiled-wpix"]:to_int(),
	       5,
	       "rgba: 250 127 127 127")
	    i = i + 1
	 end
	 if cur_scene.out and cur_scene.out["down"] then
	    show_act[i] = ywCanvasNewRectangle(
	       entity.upCanvas,
	       0, canvasWid["tiled-hpix"]:to_int() - 10,
	       canvasWid["tiled-wpix"]:to_int(),
	       5,
	       "rgba: 250 127 127 127")
	    i = i + 1
	 end
      end
   end

   if yevIsKeyUp(eve, Y_LSHIFT_KEY) then
      if (yeLen(main_widget.show_actionable) > 0) then
	 local show_act = main_widget.show_actionable
	 local sal = yeLen(show_act)
	 local i = 0

	 while i < sal do
	    ywCanvasRemoveObj(entity.upCanvas, show_act[i])
	    i = i + 1
	 end
	 yeClearArray(show_act)
      end
   end

   if yevIsGrpDown(eve, actionKeys) then
      local pjPos = ylpcsHandePos(entity.pj)
      local x_add = 0
      local y_add = 0
      local h = 30
      local w = 30

      pjPos = Pos.wrapp(pjPos)
      if entity.pj.y:to_int() == LPCS_UP then
	 y_add = -40
	 x_add = 5
	 h = 60
      elseif entity.pj.y:to_int() == LPCS_LEFT then
	 x_add = -40
	 y_add = 20
	 w = 40
      elseif entity.pj.y:to_int() == LPCS_DOWN then
	 y_add = lpcs.h_sprite
	 x_add = 5
	 h = 40
      else
	 y_add = 20
	 x_add = lpcs.w_sprite
	 w = 40
      end
      local r = Rect.new(pjPos:x() + x_add, pjPos:y() + y_add, w, h)
      --ywCanvasNewRectangle(entity.upCanvas, ywRectX(r.ent), ywRectY(r.ent),
      --ywRectW(r.ent), ywRectH(r.ent), "rgba: 10 10 255 127")
      local e_actionables = entity.actionables
      local i = 0

      while  i < yeLen(e_actionables) do
	 if ywRectCollision(r.ent, e_actionables[i].rect) and
	 checkTiledCondition(e_actionables[i]) then
	    local actioned = phq.actioned[entity.cur_scene_str:to_string()]
	    local act_cnt = actioned[e_actionables[i].name:to_string()]

	    act_cnt = yeGetInt(act_cnt) + 1
	    actioned[e_actionables[i].name:to_string()] = act_cnt
	    -- save here the number of time this object have been actioned
	    phq_do_action(entity, e_actionables[i])
	    if yeGetInt(entity.require_ret) == 1 then
	       return YEVE_ACTION
	    end
	 end
	 i = i + 1
      end

      local col = ylaCanvasCollisionsArrayWithRectangle(entity.mainScreen,
							r:cent())
      col = Entity.wrapp(col)
      --print("action !", Pos.wrapp(pjPos.ent):tostring(), Pos.wrapp(r.ent):tostring(), yeLen(col))
      i = 0
      while i < yeLen(col) do
	 local c = col[i]
	 if yeGetInt(c.is_npc) > 0 then
	    local dialogue = col[i].dialogue
	    if startDialogue(entity, c, dialogue) == YEVE_ACTION then
	       return YEVE_ACTION
	    elseif c.small_talk then
	       smallTalk(entity, c)
	    end
	 end
	 i = i + 1
      end
   end

   if is_upkey_up or is_downkey_up then
      if entity.pj.move.left_right > 0 then
	 entity.pj.y = LPCS_RIGHT
      elseif entity.pj.move.left_right < 0 then
	 entity.pj.y = LPCS_LEFT
      end
      entity.pj.move.up_down = 0
   end

   if is_leftkey_up or is_rightkey_up then
      if entity.pj.move.up_down > 0 then
	 entity.pj.y = LPCS_DOWN
      elseif entity.pj.move.up_down < 0 then
	 entity.pj.y = LPCS_UP
      end
      entity.pj.move.left_right = 0
   end


   pix_mv = turn_timer * PIX_MV_PER_MS + pix_floor_left
   pix_floor_left = pix_mv - math.floor(pix_mv)

   entity.pj.mv_pix = entity.pj.mv_pix + pix_mv


   NpcTurn(entity)

   if entity.block_script then
      scripts[entity.block_script:to_string()](entity)
      return YEVE_ACTION
   end

   local mvPos = Pos.new(pix_mv * yeGetFloat(entity.pj.move.left_right),
			 pix_mv * yeGetFloat(entity.pj.move.up_down))
   ylpcsHandlerMove(entity.pj, mvPos.ent)
    local col_rel, col_obj = CheckColision(entity, entity.mainScreen, entity.pj)
    --local col_rel = NO_COLISION

    if col_rel == FIGHT_COLISION then
       local bye_guy = Entity.new_array()
       local wid_npcs = entity.npcs
       local npc_handler = nil
       local i = 0

       while i < yeLen(wid_npcs) do
	  local cur_handler = wid_npcs[i]
	  if cur_handler and
	     cur_handler.canvas and
	  cur_handler.canvas:cent() == col_obj:cent() then
	     npc_handler = cur_handler
	     break
	  end
	  i =  i + 1
       end
       if npc_handler == nil then
	  print("CAN'T FIND NPC HANDLER FOR ", col_obj)
	  ygTerminate();
	  return YEVE_ACTION
       end
       print("Start Fight !!!", col_obj, yeGet(col_obj, "dialogue"))
       print("current: ", yeGetIntAt(entity, "current"), entity:cent())
       local d_nstr = Entity.new_string(yeGetStringAt(col_obj, "dialogue"))
       bye_guy[0] = Entity.new_string("RemoveEnemy")
       bye_guy[1] = npc_handler
       StartFight(entity, eve, d_nstr, bye_guy)
       return YEVE_ACTION
    end
    --print("MV: ", ywPosToString(mvPos:cent()))
    if col_rel == NORMAL_COLISION then
       mvPos:opposite()
       ylpcsHandlerMove(entity.pj, mvPos.ent)
    end
    if (entity.pj.mv_pix > 20) then
       entity.pj.mv_pix = 0
       walkDoStep(entity, entity.pj)
    end
    reposeCam(entity, main_widget.pj)

    if run_script then
       run_script(entity)
    end

    return YEVE_ACTION
end

function destroy_phq(entity)
   local ent = Entity.wrapp(entity)

   ygRemoveFromGlobalScope("phq_wid");
   run_script = nil
   tiled.deinit()
   ent.mainScreen = nil
   ent.upCanvas = nil
   ent.current = 0
   local i = 0
   while i < yeLen(quests_info) do
      local quest = quests_info[i]
      local stalk = yeGetStringAt(quest, "stalk")

      ygUnstalk(stalk)
      i = i + 1
   end
end

-- push all caracters to dial, but read c_dial
local function dialogue_include(dial, c_dial)
   _include(dial, c_dial)
end

function ai_point_remove(useless0, useless1, name_path)
   local name = yeGetString(ygGet(yeGetString(name_path)))
   local sname = yeGetString(main_widget.cur_scene_str)
   local e_ai_point = main_widget.ai_point

   for i = 0, yeLen(e_ai_point) - 1 do
      apname = yeGetKeyAt(e_ai_point, i)
      if yeGetString(phq.env.ai_point[sname][apname]) == name then
	 phq.env.ai_point[sname][apname] = nil
	 return
      end
   end
end

function load_scene(ent, sceneTxt, entryIdx, pj_pos)
   local mainCanvas = Canvas.wrapp(ent.mainScreen)
   local upCanvas = Canvas.wrapp(ent.upCanvas)
   local x = 0
   local y = 0
   local c = mainCanvas.ent

   ent.no_chktime_t = 0
   print("start load !!! ", sceneTxt, "\n")
   if c.exit_script then
      scripts[c.exit_script:to_string()](ent)
   end
   run_script = nil
   newly_loaded = true
   if sceneTxt == nil then
      print("can load a nil scene!\n")
      return
   end
   if ent.cur_scene_str then
      saveCurDialogue(ent)
   end

   ent.cur_scene_str = sceneTxt

   local scene = scenes[sceneTxt]

   if phq.actioned[ent.cur_scene_str:to_string()] == nil then
      phq.actioned[ent.cur_scene_str:to_string()] = {}
   end

   scene = Entity.wrapp(scene)

   -- clean old stuff :(
   upCanvas.ent.objs = {}
   upCanvas.ent.cam = Pos.new(0, 0).ent
   c.objs = {}
   c.objects = {}
   c.exit_script = nil
   c.tile_script = nil
   c.enter_script = nil

   if (scene == nil) then
      print("Can not load scene: sceneTxt")
   end

   tiled.fileToCanvas(scene.tiled:to_string(), c:cent(),
		      upCanvas.ent:cent())
   if (c.tile_script) then
      run_script = scripts[c.tile_script:to_string()]
   end

   if yIsNNil(scene.dialogues) then
      o_dialogues = File.jsonToEnt(yeGetString(scene.dialogues))
   end
   dialogue_include(o_dialogues, o_dialogues)
   yeCopy(o_dialogues, dialogues)

   if saved_scenes[ent.cur_scene_str:to_string()] then
      ent.mainScreen.objects = saved_scenes[ent.cur_scene_str:to_string()].o
      local patch = saved_scenes[ent.cur_scene_str:to_string()].d
      if (yeType(patch) == YARRAY) then
	 yePatchAply(dialogues, patch)
      end
      tmpp = yePatchCreate(o_dialogues, dialogues)
   end
   c.cam = Pos.new(0, 0).ent
   -- Pj info:

   local objects = ent.mainScreen.objects
   local npc_idx = 0
   local i = 0
   local j = 0
   local k = 0
   local l = 0
   local m = 0
   local generic_npc_id = 0
   ent.npcs = {}
   ent.enemies = {}
   ent.exits = {}
   ent.actionables = {}
   ent.triggers = {}
   ent.misc = {}
   ent.ai_point = {}
   ent.npc_act = {}
   ent.cur_scene = scene
   local e_npcs = ent.npcs
   local e_exits = ent.exits
   local e_actionables = ent.actionables
   local e_misc = ent.misc
   local e_triggers = ent.triggers

   while i < yeLen(objects) do
      local obj = objects[i]
      local layer_name = obj.layer_name
      local npc_name = yeGetString(yeGet(obj, "name"))
      local npc = npcs[npc_name]
      local is_ai_point = false

      local ai = yeGetStringAt(obj, "ai")
      local walkTalker = yIsNNil(yeGet(obj, "WalkTalk"))

      if obj.ai_point then
	 ent.ai_point[npc_name] = Entity.new_copy(obj)

	 local ap = phq.env.ai_point
	 if ap and ap[sceneTxt] then
	    is_ai_point = true
	    npc_name = yeGetString(ap[sceneTxt][npc_name])
	    npc = npcs[npc_name]
	 end
      end

      local is_here = checkNpcPresence(obj, npc, sceneTxt, is_ai_point)
      if layer_name:to_string() == "NPC" and is_here then

	 local npc_dialogue = yeGet(npc, "dialogue")

	 if yeType(npc_dialogue) ~= YSTRING then
	    yeRemoveChild(npc, "dialogue")
	    npc_dialogue = nil
	 else
	    npc_dialogue = yeGetString(npc_dialogue)
	 end

	 local pos = Pos.new_copy(obj.rect)
	 if yeGetString(npc.type) == "sprite" then
	    local sp = yeGet(npc, "sprite");
	    local s = yeGetIntAt(sp, "size")
	    -- TODO: here we assume the sprite is 32/32 but we should get the real value
	    pos:sub(s / 2, s / 2)
	    npc = sprite_man.createHandler(npc, c, e_npcs, npc_name)
	    sprite_man.handlerSetPos(npc, pos.ent)
	    if yeGetString(obj.Rotation) == "left" then
	       yeSetAt(npc, "y_offset", 32)
	    elseif yeGetString(obj.Rotation) == "right" then
	       yeSetAt(npc, "y_offset", 96)
	    elseif yeGetString(obj.Rotation) == "down" then
	       yeSetAt(npc, "y_offset", 64)
	    else -- y offset is 0 for "up"
	    end
	 else
	    dressup.dressUp(npc)
	    npc = lpcs.createCaracterHandler(npc, c, e_npcs, npc_name)
	    --print("obj (", i, "):", obj, npcs[obj.name:to_string()], obj.rect)
	    local pos = Pos.new_copy(obj.rect)
	    pos:sub(20, 50)
	    lpcs.handlerMove(npc, pos.ent)
	    lpcs.handlerSetOrigXY(npc, 0, lpcsStrToDir(yeGetString(obj.Rotation)))
	 end
	 npc = Entity.wrapp(npc)
	 generic_handlerRefresh(npc)

	 if yeGetIntAt(obj, "Agresive") == 1 or walkTalker then
	    if yIsNil(ai) then
	       yePushBack(ent.enemies, npc)
	       yePushBack(npc, pos.ent, "orig_pos")
	    end
	    if walkTalker then
	       npc.canvas.agresive = AGRESIVE_TALKER
	    else
	       npc.canvas.agresive = AGRESIVE_ATTACKER
	    end
	 end
	 if npc.char.is_generic then
	    npc.generic_id = generic_npc_id
	    generic_npc_id = generic_npc_id + 1
	 end
	 npc.canvas.Collision = 1
	 npc.canvas.is_npc = 1
	 npc.char.name = npc_name
	 print("npc_dialogue: ", npc_dialogue)
	 if yIsNNil(npc_dialogue) then
	    npc.canvas.dialogue = npc_dialogue
	 else
	    npc.canvas.dialogue = npc_name
	 end
	 npc.canvas.small_talk = npc.char["small talk"]
	 npc.canvas.dialogue_condition = npc.char.dialogue_condition
	 npc.canvas.current = npc_idx
	 npc.obj_idx = i
	 npc_idx = npc_idx + 1
	 if yIsNNil(ai) then
	    local action = Entity.new_array(ent.npc_act)
	    action[0] = npc_name
	    if yIsNNil(npc.generic_id) then
	       action.generic_id = generic_npc_id
	    end
	    action.controller = Entity.new_func(ai)
	 end
      elseif layer_name:to_string() == "Entries" then
	 yeAttach(e_exits, obj, j, obj.name:to_string(), 0)
	 j = j + 1
      elseif layer_name:to_string() == "Actionable" and
      checkObjTime(obj, phq.env.time:to_string()) then
	 e_actionables[k] = obj
	 k = k + 1
      elseif layer_name:to_string() == "MISC" then
	 yeAttach(e_misc, obj, l, obj.name:to_string(), 0)
	 l = l + 1
      elseif layer_name:to_string() == "Triggers" and
      checkObjTime(obj, phq.env.time:to_string()) then
	 e_triggers[m] = obj
	 m = m + 1
      end
      :: next_obj ::
      i = i + 1
   end

   if entryIdx < 0 or e_exits[entryIdx] == nil then
      x = 300
      y = 200
   else
      local rect = e_exits[entryIdx].rect
      local side = yeGetString(e_exits[entryIdx].side)
      x = ywRectX(rect)
      y = ywRectY(rect)
      if side == "up" or side == "up_left" or
      side == "up_right" then
	 y = y - 75
      elseif side == "down" or side == "down_right"
      or side == "down_left" then
	 y = y + ywRectH(rect) + 15
      end
      if side == "left" or side == "up_left" or
      side == "down_left" then
	 x = x - 45
      elseif side == "right" or side == "down_right"
      or side == "up_right" then
	 x = x + ywRectW(rect) + 45
      elseif side == "near_down" then
	 y = y + ywRectH(rect) - 5
      end
   end

   if pj_pos then
      ylpcsHandlerSetPos(ent.pj, pj_pos)
   else
      ylpcsHandlerSetPos(ent.pj, Pos.new(x, y).ent)
   end
   lpcs.handlerSetOrigXY(ent.pj, 0, 10)
   lpcs.handlerRefresh(ent.pj)

   if scene.exterior and phq.env.time:to_string() == "night" then
      ent.night_r = upCanvas:new_rect(0, 0, "rgba: 0 0 26 127",
				      Pos.new(window_width,
					      window_height).ent).ent
   end
   local is_raining = phq.env.is_raining
   if scene.exterior and  is_raining and is_raining > 0 then
      local i = 0
      ent.rain_a = {}

      while i < 25 do
	 ent.rain_a[i] = upCanvas:new_rect(0, 0, "rgba: 200 200 200 255",
					   Pos.new(1, 20).ent).ent
	 i = i + 1
      end
      if (is_raining > 1) then
	 local pjPos = Pos.wrapp(ylpcsHandePos(main_widget.pj))

	 pushSmallTalk("Ohh it's raining again", pjPos:x(), pjPos:y())
      end
   end

   reposeCam(ent, ent.pj)
   if (c.enter_script) then scripts[c.enter_script:to_string()](ent) end
end

function add_stat_hook(entity, stat, hook, val, comp_type)
   entity.st_hooks[stat] = {}
   entity.st_hooks[stat].hook = ygGet(hook)
   entity.st_hooks[stat].val = val
   entity.st_hooks[stat].comp_type = comp_type
end

function fight_mode_wid()
   local vnGameWid = ylaFileToEnt(YJSON, "./fight_mode.json")
   local vnWid = Entity.new_array()

   vnScene(main_widget, nil, vnGameWid, vnWid)
   vnWid.next = main_widget.next
end

function create_phq(entity, eve, menu)
   -- keep saved data
   local sav_dir = yeGetStringAt(entity, "saved_dir")
   local sav_data = yeGet(entity, "saved_data")
   local pj_pos = nil

   phq_turn_cnt = 0
   dressup.setObjects("phq.objects")
   yeIncrRef(sav_data)
   yeClearArray(entity)
   yePushBack(entity, sav_data, "saved_data")
   if (yIsNNil(sav_dir)) then
      yeCreateString(sav_dir, entity, "saved_dir");
   end
   yeDestroy(sav_data)

   local container = Container.init_entity(entity, "stacking")
   local ent = container.ent
   local scenePath = nil

   main_widget = Entity.wrapp(entity)
   ygPushToGlobalScope(entity, "phq_wid");
   main_widget["<type>"] = "phq"
   main_widget.next = "phq:menus.main"
   main_widget["next-lose"] = "phq:menus.game over"
   main_widget.show_actionable = {}
   npcs = Entity.wrapp(ygGet("phq.npcs"))
   ent.cur_scene_str = nil
   tiled.setAssetPath("./tileset")
   jrpg_fight.objects = phq.objects
   is_end_of_chapter = false

   _include(phq.objects, phq.objects)
   _include(npcs, npcs)
   _include(phq.game_senes, phq.game_senes)
   _include(phq["vn-scenes"], phq["vn-scenes"])

   ent.st_hooks = {}
   ent.gmenu_hook = {}

   ent.dialogues = dialogues

   add_stat_hook(ent, "life", "FinishGame", 0, PHQ_INF)
   if ent.saved_data then
      scenePath = ent.saved_data.cur_scene_str
      pj_pos = ent.saved_data.pj_pos
   else
      scenePath = Entity.new_string("house1")
   end
   Entity.new_func("phq_action", ent, "action")

   local mainCanvas = Canvas.new_entity(entity, "mainScreen")
   local upCanvas = Canvas.new_entity(entity, "upCanvas")
   ent["turn-length"] = TURN_LENGTH
   ent.entries = {}
   ent.background = "rgba: 127 127 127 255"
   ent.entries[0] = mainCanvas.ent
   ent.entries[1] = upCanvas.ent
   local ret = container:new_wid()
   ent.destroy = Entity.new_func("destroy_phq")

   ent.soundcallgirl = ySoundMusicLoad("./callgirl.mp3")
   ent.soundhouse = ySoundMusicLoad("./house_music.mp3")
   ent.soundtatata = ySoundMusicLoad("./rekuiemu.mp3")

   --ySoundPlayLoop(ent.soundtatata)

   ent.pj = nil
   dressup.dressUp(phq.pj)
   lpcs.createCaracterHandler(phq.pj, mainCanvas.ent, ent, "pj")
   local wid_size = yeGet(entity, "wid-pix");

   window_width = ywRectW(wid_size);
   window_height = ywRectH(wid_size);

   load_scene(ent, yeGetString(yeToLower(scenePath)), 0, pj_pos)
   ent.pj.mv_pix = Entity.new_float(0)
   ent.pj.move = {}
   ent.pj.move.up_down = Entity.new_float(0)
   ent.pj.move.left_right = Entity.new_float(0)
   local i = 0
   while i < yeLen(quests_info) do
      local name = yeGetKeyAt(quests_info, i)
      local quest = quests_info[i]
      local stalk = yeGetStringAt(quest, "stalk")
      local stalked = ygGet(stalk)
      local stalk_sart = yeGetIntAt(quest, "stalk_sart")

      if yLovePtrToNumber(stalked) == 0 then
	 ygReCreateInt(stalk, stalk_sart)
      end
      local arg = Entity.new_array()
      yePushBack(arg, ent)
      yeCreateString(name, arg)
      ygStalk(stalk, Entity.new_func("quest_update"), arg)
      i = i + 1
   end
   if ent.saved_data == nil then
      phq.quests.school_sub = 0
   end
   ywCanvasDisableWeight(mainCanvas.ent)
   ywCanvasDisableWeight(upCanvas.ent)
   -- call current quests script
   i = 0

   while i < yeLen(quests_info) do
      local qi_scripts = quests_info[i].scripts
      local j = 0
      local stalk_path = nil
      local cur = nil

      if yIsNil(qi_scripts) then
	 goto next_loop
      end

      stalk_path = yeGetStringAt(quests_info[i], "stalk")
      cur = yeGetInt(ygGet(stalk_path))

      quest_try_Call_script(ent, qi_scripts, cur)
      :: next_loop ::
      i = i + 1
   end
   if phq_only_fight == 1 then
      fight_mode_wid()
   end
   return ret
end
