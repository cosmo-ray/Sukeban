local tiled = Entity.wrapp(ygGet("tiled"))
local jrpg_fight = Entity.wrapp(ygGet("jrpg-fight"))
local dialogue_box = Entity.wrapp(ygGet("DialogueBox"))
lpcs = Entity.wrapp(ygGet("lpcs"))
sprite_man = Entity.wrapp(ygGet("sprite-man"))
local phq = Entity.wrapp(ygGet("phq"))
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

-- set as global so can be use by ai
pix_mv = 0
pix_floor_left = 0
local PIX_MV_PER_MS = 5
local TURN_LENGTH = Y_REQUEST_ANIMATION_FRAME

local NO_COLISION = 0
local NORMAL_COLISION = 1
local CHANGE_SCENE_COLISION = 2
local FIGHT_COLISION = 3
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
      return ylpcsHandePos(npc)
   end
end

function dressUp(caracter)
   local e = caracter.equipement
   local objs = phq.objects
   local clothes = nil

   if (yIsNil(caracter.clothes)) then
      clothes = Entity.new_array(caracter, "clothes")
   else
      clothes = caracter.clothes
   end

   if caracter.equipement == nil then
      goto hair;
   end

   if e.feet then
      local cur_o = objs[yeGetString(e.feet)]
      if (yIsNil(cur_o)) then
	 print("can't find ", yeGetString(e.feet))
      end
      if (cur_o.path) then
	 yeCreateString(cur_o.path:to_string(), clothes)
      end
   end

   if e.legs then
      local cur_o = objs[yeGetString(e.legs)]
      if (yIsNil(cur_o)) then
	 print("can't find ", yeGetString(e.legs))
      end
      if (cur_o.path) then
	 yeCreateString(cur_o.path:to_string(), clothes)
      end
   end

   if e.torso then
      local cur_o = objs[yeGetString(e.torso)]
      if (cur_o.path) then
	 yeCreateString(cur_o.path:to_string(), clothes)
      end
   end

   :: hair ::
   if caracter.hair then
      yeCreateString("hair/" .. caracter.sex:to_string() .. "/" ..
		     caracter.hair[0]:to_string() .. "/" ..
		     caracter.hair[1]:to_string() .. ".png",
		     clothes)
   end
end

local function reposScreenInfo(ent, x0, y0)
   ywCanvasObjSetPos(ent.night_r, x0, y0)
   ywCanvasObjSetPos(ent.life_txt, x0 + 460, y0 + 10)
   ywCanvasObjSetPos(ent.life_nb, x0 + 510, y0 + 10)
   dialogue_box.set_pos(ent.box, 40 + x0, 40 + y0)
   for i = 0, yeLen(ent.rain_a) - 1 do
      local r = ent.rain_a[i]
      local x = yuiRand() % window_width
      local y = yuiRand() % window_height

      ywCanvasObjSetPos(r, x + x0, y + y0)
   end
end

function reposeCam(main, xadd, yadd)
   local canvas = main.mainScreen
   local upCanvas = main.upCanvas
   local pjPos = Pos.wrapp(ylpcsHandePos(main.pj))
   local x0 = pjPos:x() - window_width / 2
   local y0 = pjPos:y() - window_height / 2

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
   mod.recive = Entity.new_func("recive")
   mod.remove = Entity.new_func("remove")
   mod.quest_script = Entity.new_func("call_quest_script")
   mod.use_time_point = Entity.new_func("use_time_point")
   mod.changeScene = Entity.new_func("changeScene")
   mod.gotoJail = Entity.new_func("gotoJail")
   mod.openGlobMenu = Entity.new_func("openGlobMenu")
   mod.setCurStation = Entity.new_func("setCurStation")
   mod.join_team = Entity.new_func("join_team")
   mod.leave_team = Entity.new_func("leave_team_callback")
   mod.ai_point_remove = Entity.new_func(ai_point_remove)
   mod.chk_affection = Entity.new_func(chk_affection)
end

function load_game(save_dir)
   local game = ygGet("phq:menus.game")
   game = Entity.wrapp(game)
   game.saved_dir = save_dir
   game.saved_data = ygFileToEnt(YJSON, save_dir.."/misc.json")
   yeDestroy(game.saved_data)
   local pj = ygFileToEnt(YJSON, save_dir.."/pj.json")
   phq.pj = pj
   yeDestroy(pj)
   local env = ygFileToEnt(YJSON, save_dir.."/env.json")
   game.saved_data.pj_pos = ygFileToEnt(YJSON, save_dir.."/pj-pos.json")
   saved_scenes = Entity._wrapp_(ygFileToEnt(YJSON,
					       save_dir.."/saved-scenes.json"),
				   true)
   phq.env = env
   yeDestroy(env)
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
   ywidNext(ygGet("phq:menus.game"))
   --yCallNextWidget(entity);
end

function continue(entity)
   return load_game(ygUserDir() .. "saved/cur")
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
   local p = yePatchCreate(o_dialogues, dialogues)
   saved_scenes[main.cur_scene_str:to_string()].d = Entity.wrapp(p)
   yeDestroy(p)
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

local function CheckColisionExit(col, ret, obj)
   yeDestroy(col)
   return ret, obj
end

local this_door_is_lock_msg = 0

function CheckColision(main, canvasWid, pj)
   local pjPos = ylpcsHandePos(pj)
   local colRect = Rect.new(ywPosX(pjPos) + 10, ywPosY(pjPos) + 30, 20, 20).ent
   local exites = main.exits
   local cur_time = phq.env.time:to_string()
   local i = 0

   while i < yeLen(exites) do
      local rect = exites[i].rect
      if ywRectCollision(rect, colRect) then
	 local exit = exites[i]
	 if checkObjTime(exit, cur_time) then
	    local nextSceneTxt = yeGetString(yeToLower(exit.nextScene))
	    if yIsNil(nextSceneTxt) == false then
	       load_scene(main, nextSceneTxt, yeGetInt(exit.entry))
	    else
	       exit.disable_timer = os.time()
	       phq_do_action(main, exit)
	    end
	    return CHANGE_SCENE_COLISION
	 elseif yeGetInt(exit.disable_timer) == 0 then
	    local TIME_RESET = 1000000

	    if this_door_is_lock_msg < 1 then
	       this_door_is_lock_msg = TIME_RESET
	       printMessage(main, nil, "It's close !")
	    else
	       print(this_door_is_lock_msg)
	       this_door_is_lock_msg = this_door_is_lock_msg - ywidGetTurnTimer()
	    end
	 end
      end
      i = i + 1
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

   local col = ywCanvasNewCollisionsArrayWithRectangle(canvasWid, colRect)

   col = Entity.wrapp(col)
   i = 0
   while i < yeLen(col) do
      local obj = col[i]

      if yeGetIntAt(obj, "Collision") == 1 and
      ywCanvasCheckColisionsRectObj(colRect, obj) then
	 local agresivity = yeGetIntAt(obj, "agresive")

	 if agresivity > 0 then
	    if agresivity == AGRESIVE_ATTACKER then
	       return CheckColisionExit(col, FIGHT_COLISION, obj)
	    elseif agresivity == AGRESIVE_TALKER then
	       local dialogue = obj.dialogue

	       startDialogue(main_widget, obj, dialogue)
	       obj.agresive = NOT_AGRESIVE
	       yeRemoveChild(main_widget.enemies,
			     npc_handler_from_canva(obj))
	       return YEVE_ACTION
	    end
	 end
	 return CheckColisionExit(col, NORMAL_COLISION)
      end
      i = i + 1
   end
   return CheckColisionExit(col, NO_COLISION)
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

function phq_action(entity, eve)
   collectgarbage("collect")
   if yeGetIntAt(entity, "current") > 1 then
      return NOTHANDLE
   end

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
      print("do: ", action_eve)
      yeUnsetFirst(school_events)
      return ret
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

   if yevIsGrpDown(eve, upKeys) then
      entity.pj.move.up_down = -1
      entity.pj.y = LPCS_UP
   elseif yevIsGrpDown(eve, downKeys) then
      entity.pj.move.up_down = 1
      entity.pj.y = LPCS_DOWN
   end

   if yevIsGrpDown(eve, leftKeys) then
      entity.pj.move.left_right = -1
      entity.pj.y = LPCS_LEFT
   elseif yevIsGrpDown(eve, rightKeys) then
      entity.pj.move.left_right = 1
      entity.pj.y = LPCS_RIGHT
   end

   if yevIsKeyDown(eve, Y_C_KEY) then
      return openGlobMenu(entity, GM_STATS_IDX)
   elseif yevIsKeyDown(eve, Y_I_KEY) then
      return openGlobMenu(entity, GM_INV_IDX)
   elseif yevIsKeyDown(eve, Y_M_KEY) then
      return openGlobMenu(entity, GM_MAP_IDX)
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
	    local cr = e_actionables[i].rect

	    show_act[i] = ywCanvasNewRectangle(entity.upCanvas,
					       ywRectX(cr), ywRectY(cr),
					       ywRectW(cr), ywRectH(cr),
					       "rgba: 250 250 127 127")
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

      pjPos = Pos.wrapp(pjPos)
      if entity.pj.y:to_int() == LPCS_UP then
	 y_add = -25
	 x_add = lpcs.w_sprite / 2
      elseif entity.pj.y:to_int() == LPCS_LEFT then
	 x_add = -25
	 y_add = lpcs.h_sprite / 2
      elseif entity.pj.y:to_int() == LPCS_DOWN then
	 y_add = lpcs.h_sprite + 20
	 x_add = lpcs.w_sprite / 2
      else
	 y_add = lpcs.h_sprite / 2
	 x_add = lpcs.w_sprite + 20
      end
      local r = Rect.new(pjPos:x() + x_add, pjPos:y() + y_add, 10, 10)
      local e_actionables = entity.actionables
      local i = 0

      while  i < yeLen(e_actionables) do
	 if ywRectCollision(r.ent, e_actionables[i].rect) and
	 checkTiledCondition(e_actionables[i]) then
	    local actioned = phq.actioned[entity.cur_scene_str:to_string()]
	    local act_cnt = actioned[e_actionables[i].name:to_string()]

	    act_cnt = yeGetInt(act_cnt) + 1
	    actioned[e_actionables[i].name:to_string()] = act_cnt
	    print("ACTION: ", phq.actioned, e_actionables[i].usable_once,
		  e_actionables[i].Arg0)
	    -- save here the number of time this object have been actioned
	    phq_do_action(entity, e_actionables[i])
	    if yeGetInt(entity.require_ret) == 1 then
	       return YEVE_ACTION
	    end
	 end
	 i = i + 1
      end

      local col = ywCanvasNewCollisionsArrayWithRectangle(entity.mainScreen,
							  r:cent())
      col = Entity.wrapp(col)
      --print("action !", Pos.wrapp(pjPos.ent):tostring(), Pos.wrapp(r.ent):tostring(), yeLen(col))
      i = 0
      while i < yeLen(col) do
	 local c = col[i]
	 if yeGetInt(c.is_npc) > 0 then
	    local dialogue = col[i].dialogue
	    if startDialogue(entity, c, dialogue) == YEVE_ACTION then
	       yeDestroy(col)
	       return YEVE_ACTION
	    elseif c.small_talk then
	       smallTalk(entity, c)
	    end
	 end
	 i = i + 1
      end
      yeDestroy(col)
   end

   if yevIsGrpUp(eve, upKeys) or yevIsGrpUp(eve, downKeys) then
      if entity.pj.move.left_right > 0 then
	 entity.pj.y = LPCS_RIGHT
      elseif entity.pj.move.left_right < 0 then
	 entity.pj.y = LPCS_LEFT
      end
      entity.pj.move.up_down = 0
   end

   if yevIsGrpUp(eve, leftKeys) or yevIsGrpUp(eve, rightKeys) then
      if entity.pj.move.up_down > 0 then
	 entity.pj.y = LPCS_DOWN
      elseif entity.pj.move.up_down < 0 then
	 entity.pj.y = LPCS_UP
      end
      entity.pj.move.left_right = 0
   end


   pix_mv = turn_timer * PIX_MV_PER_MS + pix_floor_left
   pix_floor_left = pix_mv - math.floor(pix_mv)

   entity.pj.mv_pix = entity.pj.mv_pix + math.abs(pix_mv)


   NpcTurn(entity)

   if entity.block_script then
      scripts[entity.block_script:to_string()](entity)
      return YEVE_ACTION
   end

   local mvPos = Pos.new(pix_mv * entity.pj.move.left_right,
			 pix_mv * entity.pj.move.up_down)
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
    if (entity.pj.mv_pix > 6) then
       entity.pj.mv_pix = 0
       walkDoStep(entity, entity.pj)
    end
    reposeCam(entity)

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

   o_dialogues = File.jsonToEnt(yeGetString(scene.dialogues))
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
   local i = 0
   local npc_idx = 0
   local j = 0
   local k = 0
   local l = 0
   local generic_npc_id = 0
   ent.npcs = {}
   ent.enemies = {}
   ent.exits = {}
   ent.actionables = {}
   ent.misc = {}
   ent.ai_point = {}
   ent.npc_act = {}
   ent.cur_scene = scene
   local e_npcs = ent.npcs
   local e_exits = ent.exits
   local e_actionables = ent.actionables
   local e_misc = ent.misc

   while i < yeLen(objects) do
      local obj = objects[i]
      local layer_name = obj.layer_name
      local npc_name = yeGetString(yeGet(obj, "name"))
      local npc = npcs[npc_name]
      local is_ai_point = false

      if obj.ai_point then
	 ent.ai_point[npc_name] = Entity.new_copy(obj)

	 local ap = phq.env.ai_point
	 if ap and ap[sceneTxt] then
	    is_ai_point = true
	    npc_name = yeGetString(ap[sceneTxt][npc_name])
	    npc = npcs[npc_name]
	 end
      end
      local npc_dialogue = yeGetStringAt(npc, "dialogue")

      if layer_name:to_string() == "NPC" and
      checkNpcPresence(obj, npc, sceneTxt, is_ai_point) then

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
	    dressUp(npc)
	    npc = lpcs.createCaracterHandler(npc, c, e_npcs, npc_name)
	    --print("obj (", i, "):", obj, npcs[obj.name:to_string()], obj.rect)
	    local pos = Pos.new_copy(obj.rect)
	    pos:sub(20, 50)
	    lpcs.handlerMove(npc, pos.ent)
	    lpcs.handlerSetOrigXY(npc, 0, lpcsStrToDir(yeGetString(obj.Rotation)))
	 end
	 npc = Entity.wrapp(npc)
	 generic_handlerRefresh(npc)
	 local ai = yeGetStringAt(obj, "ai")
	 local walkTalker = yIsNNil(yeGet(obj, "WalkTalk"))
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

   ent.life_txt = ywCanvasNewTextExt(upCanvas.ent, 360, 10,
				     Entity.new_string("life: "),
				     "rgba: 255 255 255 255")
   upCanvas:remove(ent.life_nb )
   ent.life_nb = ywCanvasNewTextExt(upCanvas.ent, 410, 10,
				    Entity.new_string(math.floor(phq.pj.life:to_int())),
				    "rgba: 255 255 255 255")
   reposeCam(ent)
   if (c.enter_script) then scripts[c.enter_script:to_string()](ent) end
end

function add_stat_hook(entity, stat, hook, val, comp_type)
   entity.st_hooks[stat] = {}
   entity.st_hooks[stat].hook = ygGet(hook)
   entity.st_hooks[stat].val = val
   entity.st_hooks[stat].comp_type = comp_type
end

function create_phq(entity)
   -- keep saved data
   local sav_dir = yeGetStringAt(entity, "saved_dir")
   local sav_data = yeGet(entity, "saved_data")
   local pj_pos = nil

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
   yJrpgFightSetCombots("phq.combots")
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
   dressUp(phq.pj)
   lpcs.createCaracterHandler(phq.pj, mainCanvas.ent, ent, "pj")
   local wid_size = yeGet(entity, "wid-pix");

   window_width = ywRectW(wid_size);
   window_height = ywRectH(wid_size);

   load_scene(ent, yeGetString(yeToLower(scenePath)), 0, pj_pos)
   ent.pj.mv_pix = Entity.new_float(0)
   ent.pj.move = {}
   ent.pj.move.up_down = 0
   ent.pj.move.left_right = 0
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
   return ret
end
