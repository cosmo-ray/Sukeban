local tiled = Entity.wrapp(ygGet("tiled"))
local dialogue_box = Entity.wrapp(ygGet("DialogueBox"))
local dialogue = Entity.wrapp(ygGet("Dialogue"))
local lpcs = Entity.wrapp(ygGet("lpcs"))
local phq = Entity.wrapp(ygGet("phq"))
local modPath = Entity.wrapp(ygGet("phq.$path")):to_string()
local npcs = Entity.wrapp(ygGet("phq.npcs"))
local scenes = Entity.wrapp(ygGet("phq.scenes"))
local dialogues = nil
local window_width = 800
local window_height = 600
local sleep_time = 0
local pj_pos = nil

local NO_COLISION = 0
local NORMAL_COLISION = 1
local CHANGE_SCENE_COLISION = 2
local PHQ_SUP = 0
local PHQ_INF = 1

DAY_STR = {"monday", "tuesday", "wensday", "thursday",
	   "friday", "saturday", "sunday"}

local function doSleep(ent, upCanvas)
   ywCanvasRemoveObj(upCanvas.ent, ent.sleep_r)

   if sleep_time > 200 then
      ent.sleep = nil
      sleep_time = 0
      return true
   end

   local pjPos = Pos.wrapp(ylpcsHandePos(ent.pj))
   local x0 = pjPos:x() - window_width / 2
   local y0 = pjPos:y() - window_height / 2

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
   sleep_time = sleep_time + 1
   return false
end

local function reposScreenInfo(ent, x0, y0)
   ywCanvasObjSetPos(ent.night_r, x0, y0)
   ywCanvasObjSetPos(ent.life_txt, x0 + 360, y0 + 10)
   ywCanvasObjSetPos(ent.life_nb, x0 + 410, y0 + 10)
   dialogue_box.set_pos(ent.box, 40 + x0, 40 + y0)
end

local function reposeCam(main)
   local canvas = main.mainScreen
   local upCanvas = main.upCanvas
   local pjPos = Pos.wrapp(ylpcsHandePos(main.pj))
   local x0 = pjPos:x() - window_width / 2
   local y0 = pjPos:y() - window_height / 2

   ywPosSet(canvas.cam, x0, y0)
   ywPosSet(upCanvas.cam, x0, y0)
   reposScreenInfo(main, x0, y0)
end

function backToGameOnEnter(wid, eve)
   eve = Event.wrapp(eve)

   while eve:is_end() == false do
      if eve:type() == YKEY_DOWN and eve:key() == Y_ENTER_KEY then
	 backToGame(wid)
      end
      eve = eve:next()
   end
   return YEVE_NOTHANDLE
end

function backToGame(wid)
   local main = Entity.wrapp(ywCntWidgetFather(wid))

   wid = Entity.wrapp(wid)
   if wid.oldTimer then
      main["turn-length"] = wid.oldTimer
   end
   ywCntPopLastEntry(main)
   main.current = 0
   return YEVE_ACTION
end

function EndDialog(wid, eve, arg)
   wid = Entity.wrapp(yDialogueGetMain(wid))
   local main = Entity.wrapp(ywCntWidgetFather(wid))
   wid.main = nil
   if wid.src then
      wid.src.isBlock = wid.isBlock
      wid.src.block = wid.block
      wid.src = nil
   end
   ywCntPopLastEntry(main)
   main.current = 0
   return YEVE_ACTION
end

function CombatEnd(wid, main, winner)
   local main = Entity.wrapp(main)
   local wid = Entity.wrapp(wid)
   local canvas = Canvas.wrapp(main.mainScreen)

   if yLovePtrToNumber(winner) == 3 then
      yCallNextWidget(main:cent())
   end
   canvas:remove(main.life_nb )
   main.life_nb = ywCanvasNewTextExt(canvas.ent, 410, 10,
				     Entity.new_string(math.floor(phq.pj.life:to_int())),
				     "rgba: 255 255 255 255")

   wid.main = nil
   ywCntPopLastEntry(main)
   main.current = 0
   ySoundStop(main.soundcallgirl:to_int())
   --print("end:", main, winner)
end

function StartFight(wid, eve, arg)
   owid = wid
   wid = yDialogueGetMain(wid)
   local main = Entity.wrapp(ywCntWidgetFather(wid))
   local fWid = Entity.new_array()
   wid = Entity.wrapp(wid)
   ySoundPlayLoop(main.soundcallgirl:to_int())

   fWid["<type>"] = "jrpg-fight"
   fWid.endCallback = Entity.new_func("CombatEnd")
   fWid.endCallbackArg = main
   fWid.player = phq.pj
   fWid.enemy = main.npcs[wid.npc_nb:to_int()].char
   fWid.enemy.life = fWid.enemy.max_life
   print(fWid.endCallbackArg:cent())
   EndDialog(owid, eve, arg)
   ywPushNewWidget(main, fWid)
   print("2:", fWid.endCallbackArg:cent())
   return YEVE_ACTION
end

function takeObject(main, actionable_obj, what, nb)
   local obj = phq.pj.inventory[yeGetString(what)]
   actionable_obj = Entity.wrapp(actionable_obj)

   if actionable_obj.is_used then
      return YEVE_ACTION
   end
   if obj then
      yeSetInt(obj, yeGetInt(obj) + yeGetInt(nb))
   else
      phq.pj.inventory[yeGetString(what)] = yeGetInt(nb)
   end
   actionable_obj.is_used = true
   return printMessage(main, obj, Entity.new_string("get " ..
						    math.floor(yeGetInt(nb)) ..
						    " " ..
						    yeGetString(what)))
end

function pay(wid, eve, arg, cost, okAction, noDialogue)
   cost = yeGetInt(cost)
   if phq.pj.inventory.money > cost then
      local money = phq.pj.inventory.money
      yeSetInt(money, money:to_int() - cost)
      return ywidAction(okAction, wid, eve, arg)
   end
   return dialogue["change-text"](wid, eve, arg, noDialogue)
end

function increaseStat(wid, caracter, stat, nb, max)
   local s = caracter[stat]

   yeSetInt(s, s + nb)
   if s > max then
      yeSetInt(s, max)
   end
   return printMessage(wid, caracter,
		       Entity.new_string(stat .. " increase to " ..
					    yeGetInt(s)))
end

function GetDrink(wid, eve, arg)
   local ent = Entity.wrapp(ywCntWidgetFather(yDialogueGetMain(wid)))
   local canvas = Canvas.wrapp(ent.mainScreen)
   increaseStat(ent, phq.pj, "drunk", 9, 100)
   increaseStat(ent, phq.pj, "life", 2, phq.pj.max_life:to_int())

   canvas:remove(ent.life_nb)
   ent.life_nb = ywCanvasNewTextExt(canvas.ent, 410, 10,
				    Entity.new_string(math.floor(phq.pj.life:to_int())),
                                    "rgba: 255 255 255 255")
   if phq.pj.drunk > 99 then
       ent.next = "phq:menus.end_txt"
       yCallNextWidget(ent:cent())
   end
   EndDialog(wid, eve, arg)
   return printMessage(ent, obj, Entity.new_string("get beer, or whine, or rum\n"..
						      "some kind of alcohol anyway"))
end

function GetDrink2(wid, eve, arg)
   local ent = Entity.wrapp(ywCntWidgetFather(yDialogueGetMain(wid)))
   local canvas = Canvas.wrapp(ent.mainScreen)
   increaseStat(ent, phq.pj, "drunk", 18, 100)
   increaseStat(ent, phq.pj, "life", 5, phq.pj.max_life:to_int())

   canvas:remove(ent.life_nb)
   ent.life_nb = ywCanvasNewTextExt(canvas.ent, 410, 10,
				    Entity.new_string(math.floor(phq.pj.life:to_int())),
				    "rgba: 255 255 255 255")
   if phq.pj.drunk > 99 then
       ent.next = "phq:menus.end_txt"
       yCallNextWidget(ent:cent())
   end
   EndDialog(wid, eve, arg)
   return printMessage(ent, obj, Entity.new_string("get vodka...\n"..
						      "cut with tekila"))
end

function sleep(main, obj)
   print("SLEEP")
   if phq.env.time:to_string() == "night" then
      phq.env.time = "day"
      phq.env.day = phq.env.day + 1
      if phq.env.day > 6 then
	 phq.env.day = 0
	 phq.env.week = phq.env.week + 1
      end
   else
      phq.env.time = "night"
   end
   main = Entity.wrapp(main)
   main.sleep = 1
end

function printMessage(main, obj, msg)
   local txt = yeGetString(msg)
   main = Entity.wrapp(main)
   if main.box then
      txt = yeGetString(dialogue_box.get_text(main.box)) ..
	 "\n-------------------------------\n" .. txt
      dialogue_box.rm(main.upCanvas, main.box)
      main.box = nil
   end
   dialogue_box.new_text(main.upCanvas, 0, 0,
			 txt, main, "box")
   main.box_t = 0
end

function startDialogue(main, obj, dialogue)
   dialogue = Entity.wrapp(dialogue)
   print("Start Dialogue !!!!", obj, dialogue)
   if dialogue and dialogues[dialogue:to_string()] then
      local entity = Entity.wrapp(main)
      local obj = Entity.wrapp(obj)
      local dialogueWid = Entity.new_array()
      local npc = nil
      local npc_nb = -1
      if obj.current then
	 npc = entity.npcs[obj.current:to_int()].char
	 npc_nb = obj.current
      else
	 npc = obj
      end
      local dialogue = dialogues[dialogue:to_string()]

      print(dialogue)
      if dialogue.dialogue then
	 yeCopy(dialogue, dialogueWid)
	 dialogueWid.src = dialogue
      else
	 dialogueWid.dialogue = dialogue
      end
      dialogueWid.npc_nb = npc_nb
      dialogueWid["<type>"] = "dialogue-canvas"
      dialogueWid.image = npc.image
      dialogueWid.name = npc.name
      ywPushNewWidget(entity, dialogueWid)
      return YEVE_ACTION
   end
   return YEVE_NOTHANDLE
end

function checkNpcPresence(npc, scene)
   if npc == nil then
      return false
   end
   if npc.calendar then
      return yeGetString(npc.calendar[DAY_STR[phq.env.day:to_int() + 1]]) == scene
   end
   return true
end

function init_phq(mod)
   Widget.new_subtype("phq", "create_phq")
   Widget.new_subtype("phq-new-game", "create_new_game")

   mod = Entity.wrapp(mod)
   mod.EndDialog = Entity.new_func("EndDialog")
   mod.StartFight = Entity.new_func("StartFight")
   mod.GetDrink = Entity.new_func("GetDrink")
   mod["GetDrink++"] = Entity.new_func("GetDrink2")
   mod.load_game = Entity.new_func("load_game")
   mod.continue = Entity.new_func("continue")
   mod.newGame = Entity.new_func("newGame")
   mod.printMessage = Entity.new_func("printMessage")
   mod.sleep = Entity.new_func("sleep")
   mod.startDialogue = Entity.new_func("startDialogue")
   mod.playSnake = Entity.new_func("playSnake")
   mod.playAstShoot = Entity.new_func("playAstShoot")
   mod.pay = Entity.new_func("pay")
   mod.takeObject = Entity.new_func("takeObject")
end

function load_game(entity, save_dir)
   print("do the same move at the last part, and you're game will be load :)")
   local game = ygGet("phq:menus.game")
   game = Entity.wrapp(game)
   game.saved_dir = save_dir
   game.saved_data = ygFileToEnt(YJSON, save_dir.."/misc.json")
   yeDestroy(game.saved_data)
   local pj = ygFileToEnt(YJSON, save_dir.."/pj.json")
   print(pj)
   phq.pj = pj
   yeDestroy(pj)
   local env = ygFileToEnt(YJSON, save_dir.."/env.json")
   pj_pos = ygFileToEnt(YJSON, save_dir.."/pj-pos.json")
   print(env)
   phq.env = env
   yeDestroy(env)
   --local tmp = ygFileToEnt(YJSON, save_dir.."/npcs.json")
   yCallNextWidget(entity);
end

function continue(entity)
   print("Continue !!!")
   return load_game(entity, "./saved/cur")
end

function saveGame(main, saveDir)
   print(saveDir)
   local destDir = "./saved/" .. saveDir
   local misc = Entity.new_array()

   yuiMkdir("./saved")
   yuiMkdir(destDir)
   misc.cur_scene_str = main.cur_scene_str
   print(misc, main.cur_scene_str)
   ygEntToFile(YJSON, destDir .. "/pj-pos.json", ylpcsHandePos(main.pj))
   ygEntToFile(YJSON, destDir .. "/npcs.json", npcs)
   ygEntToFile(YJSON, destDir .. "/pj.json", phq.pj)
   ygEntToFile(YJSON, destDir .. "/misc.json", misc)
   ygEntToFile(YJSON, destDir .. "/env.json", phq.env)
   print("saving game")
end

function saveGameCallback(wid)
   saveGame(Entity.wrapp(ywCntWidgetFather(wid)), "cur")
end

function CheckColisionTryChangeScene(main, cur_scene, direction)
   if cur_scene.out and cur_scene.out[direction] then
      local dir_info = cur_scene.out[direction]
      local nextSceneTxt = nil
      if dir_info.to then
	 nextSceneTxt = dir_info.to:to_string()
      else
	 nextSceneTxt = dir_info:to_string()
      end
      load_scene(main, nextSceneTxt, yeGetIntAt(dir_info, "entry"))
      return true
   end
   return false
end

function CheckColision(main, canvasWid, pj)
   local pjPos = ylpcsHandePos(pj)
   local colRect = ywRectCreate(ywPosX(pjPos) + 10, ywPosY(pjPos) + 30,
			       20, 20)
   local col = ywCanvasNewCollisionsArrayWithRectangle(canvasWid, colRect)

   col = Entity.wrapp(col)
   local i = 0
   while i < yeLen(main.exits) do
      local rect = main.exits[i].rect
      if ywRectCollision(rect, colRect) then
	 local nextSceneTxt = main.exits[i].nextScene:to_string()
	 load_scene(main, nextSceneTxt, yeGetInt(main.exits[i].entry))
	 yeDestroy(col)
	 yeDestroy(colRect)
	 return CHANGE_SCENE_COLISION
      end
      i = i + 1
   end
   yeDestroy(colRect)

   local cur_scene = main.cur_scene
   if ywPosX(pjPos) < 0 then
      yeDestroy(col)
      if CheckColisionTryChangeScene(main, cur_scene, "left") then
	 return CHANGE_SCENE_COLISION
      else
	 return NORMAL_COLISION
      end
   elseif ywPosY(pjPos) < 0 then
      yeDestroy(col)
      if CheckColisionTryChangeScene(main, cur_scene, "up") then
	 return CHANGE_SCENE_COLISION
      else
	 return NORMAL_COLISION
      end
   elseif ywPosX(pjPos) + lpcs.w_sprite > canvasWid["tiled-wpix"]:to_int() then
      yeDestroy(col)
      if CheckColisionTryChangeScene(main, cur_scene, "right") then
	 return CHANGE_SCENE_COLISION
      else
	 return NORMAL_COLISION
      end
   elseif ywPosY(pjPos) + lpcs.h_sprite > canvasWid["tiled-hpix"]:to_int() then
      yeDestroy(col)
      if CheckColisionTryChangeScene(main, cur_scene, "down") then
	 return CHANGE_SCENE_COLISION
      else
	 return NORMAL_COLISION
      end
   end

   i = 0
   while i < yeLen(col) do
      local obj = col[i]
      if yeGetIntAt(obj, "Collision") == 1 then
	 yeDestroy(col)
	 return NORMAL_COLISION
      end
      i = i + 1
   end
   yeDestroy(col)
   return NO_COLISION
end

function playSnake(wid)
   local wid = Entity.wrapp(wid)
   local main = nil

   if wid.isDialogue then
      wid = Entity.wrapp(yDialogueGetMain(wid))
   end
   main = Entity.wrapp(ywCntWidgetFather(wid))

   ywCntPopLastEntry(main)
   local snake = Entity.new_array()

   snake["<type>"] = "snake"
   snake.dreadful_die = 1
   snake.die = Entity.new_func("backToGame")
   snake.quit = Entity.new_func("backToGame")
   snake.hitWall = "snake:snakeWarp"
   snake.resources = "snake:resources"
   snake.background = "rgba: 255 255 255 255"
   snake.oldTimer = main["turn-length"]
   main["turn-length"] = 200000
   ywPushNewWidget(main, snake)
   return YEVE_ACTION
end

function playAstShoot(wid)
   local wid = Entity.wrapp(wid)
   local main = nil

   if wid.isDialogue then
      wid = Entity.wrapp(yDialogueGetMain(wid))
   end
   main = Entity.wrapp(ywCntWidgetFather(wid))

   ywCntPopLastEntry(main)
   local ast_shoot = Entity.new_array()

   ast_shoot["<type>"] = "asteroide-shooter"
   ast_shoot.die = Entity.new_func("backToGame")
   ast_shoot.quit = Entity.new_func("backToGame")
   ast_shoot.oldTimer = main["turn-length"]
   main["turn-length"] = 40000
   ywPushNewWidget(main, ast_shoot)
   return YEVE_ACTION
end

function pushMainMenu(main)
   local mn = Menu.new_entity()

   mn:push("back to game", Entity.new_func("backToGame"))
   mn:push("status", Entity.new_func("pushStatus"))
   mn:push("inventory", Entity.new_func("invList"))
   mn:push("save game", Entity.new_func("saveGameCallback"))
   mn:push("main menu", "callNext")
   mn.ent.background = "rgba: 255 255 255 190"
   mn.ent["text-align"] = "center"
   mn.ent.next = main.next
   ywPushNewWidget(main, mn.ent)
end

function phq_action(entity, eve, arg)
   entity = Entity.wrapp(entity)
   entity.tid = entity.tid + 1
   eve = Event.wrapp(eve)
   local st_hooks = entity.st_hooks
   local st_hooks_len = yeLen(entity.st_hooks)

   if yeGetInt(entity.current) == 2 then
      return NOTHANDLE
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
   if entity.box_t then
      if entity.box_t > 100 then
	 dialogue_box.rm(entity.upCanvas, entity.box)
	 entity.box = nil
	 entity.box_t = nil
      else
	 entity.box_t = entity.box_t + 1
      end
   elseif entity.sleep then
      if doSleep(entity, Canvas.wrapp(entity.upCanvas)) == false then
	 return YEVE_ACTION
      end
   end
   while eve:is_end() == false do
       if eve:type() == YKEY_DOWN then
	  if eve:key() == Y_ESC_KEY then
	     pushMainMenu(entity)
	     return YEVE_ACTION
	  elseif eve:is_key_up() then
             entity.move.up_down = -1
             entity.pj.y = 8
	  elseif eve:is_key_down() then
             entity.move.up_down = 1
             entity.pj.y = 10
	  elseif eve:is_key_left() then
             entity.move.left_right = -1
             entity.pj.y = 9
	  elseif eve:is_key_right() then
             entity.move.left_right = 1
             entity.pj.y = 11
          elseif eve:key() == Y_SPACE_KEY or eve:key() == Y_ENTER_KEY then
             local pjPos = ylpcsHandePos(entity.pj)
             local x_add = 0
             local y_add = 0

             pjPos = Pos.wrapp(pjPos)
             if entity.pj.y:to_int() == 8 then
                y_add = -25
                x_add = lpcs.w_sprite / 2
             elseif entity.pj.y:to_int() == 9 then
                x_add = -25
                y_add = lpcs.h_sprite / 2
             elseif entity.pj.y:to_int() == 10 then
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
		if ywRectCollision(r.ent, e_actionables[i].rect) then
		   return yesCall(ygGet(e_actionables[i].Action:to_string()),
				  entity:cent(), e_actionables[i]:cent(),
				  e_actionables[i].Arg0,
				  e_actionables[i].Arg1,
				  e_actionables[i].Arg2,
				  e_actionables[i].Arg3)
		end
		i = i + 1
	     end

	     local col = ywCanvasNewCollisionsArrayWithRectangle(entity.mainScreen, r:cent())
             col = Entity.wrapp(col)
             --print("action !", Pos.wrapp(pjPos.ent):tostring(), Pos.wrapp(r.ent):tostring(), yeLen(col))
	     i = 0
             while i < yeLen(col) do
                local dialogue = col[i].dialogue
		if startDialogue(entity, col[i], dialogue) == YEVE_ACTION then
		   yeDestroy(col)
		   return YEVE_ACTION
		end
                i = i + 1
             end
             yeDestroy(col)
	  end

        elseif eve:type() == YKEY_UP then
	  if eve:is_key_up() then
	     entity.move.up_down = 0
	  elseif eve:is_key_down() then
	     entity.move.up_down = 0
	  elseif eve:is_key_left() then
	     entity.move.left_right = 0
	  elseif eve:is_key_right() then
	     entity.move.left_right = 0
          end
          entity.pj.x = 0
       end
       eve = eve:next()
    end
   if yAnd(entity.tid:to_int(), 3) == 0 and
      (yuiAbs(entity.move.left_right:to_int()) == 1 or
       yuiAbs(entity.move.up_down:to_int()) == 1)  then
       ylpcsHandlerNextStep(entity.pj)
       lpcs.handlerRefresh(entity.pj)
    end
    local mvPos = Pos.new(3 * entity.move.left_right, 3 * entity.move.up_down)
    lpcs.handlerMove(entity.pj, mvPos.ent)
    local col_rel = CheckColision(entity, entity.mainScreen, entity.pj)
    if col_rel == NORMAL_COLISION then
       mvPos:opposite()
       lpcs.handlerMove(entity.pj, mvPos.ent)
    end
    reposeCam(entity)
    return YEVE_ACTION
end

function destroy_phq(entity)
   local ent = Entity.wrapp(entity)

   tiled.deinit()
   ent.mainScreen = nil
   ent.upCanvas = nil
   yeDestroy(dialogues)
   dialogues = nil
   ent.current = 0
end

function load_scene(ent, sceneTxt, entryIdx)
   local mainCanvas = Canvas.wrapp(ent.mainScreen)
   local upCanvas = Canvas.wrapp(ent.upCanvas)
   local x = 0
   local y = 0

   ent.cur_scene_str = sceneTxt
   print("scene txt:", sceneTxt, ent.cur_scene_str)
   local scene = scenes[sceneTxt]

   scene = Entity.wrapp(scene)
   print(scene:cent())

   -- clean old stuff :(
   upCanvas.ent.objs = {}
   upCanvas.ent.cam = Pos.new(0, 0).ent
   mainCanvas.ent.objs = {}
   mainCanvas.ent.objects = {}
   tiled.fileToCanvas(scene.tiled:to_string(), mainCanvas.ent:cent(), upCanvas.ent:cent())
   yeDestroy(dialogues)
   dialogues = nil
   dialogues = Entity.wrapp(ygFileToEnt(YJSON, yeGetString(scene.dialogues)))
   mainCanvas.ent.cam = Pos.new(0, 0).ent
   -- Pj info:
   local objects = ent.mainScreen.objects
   local i = 0
   local npc_idx = 0
   local j = 0
   local k = 0
   ent.npcs = {}
   ent.exits = {}
   ent.actionables = {}
   ent.cur_scene = scene
   local e_npcs = ent.npcs
   local e_exits = ent.exits
   local e_actionables = ent.actionables
   while i < yeLen(objects) do
      local obj = objects[i]
      local layer_name = obj.layer_name
      local npc = npcs[yeGetString(yeGet(obj, "name"))]

      if layer_name:to_string() == "NPC" and
      checkNpcPresence(npc, sceneTxt) then

	 npc = lpcs.createCaracterHandler(npc, mainCanvas.ent, e_npcs)
	 --print("obj (", i, "):", obj, npcs[obj.name:to_string()], obj.rect)
	 local pos = Pos.new_copy(obj.rect)
	 pos:sub(20, 50)
	 lpcs.handlerMove(npc, pos.ent)
	 if yeGetString(obj.Rotation) == "left" then
	    lpcs.handlerSetOrigXY(npc, 0, 9)
	 elseif yeGetString(obj.Rotation) == "right" then
	    lpcs.handlerSetOrigXY(npc, 0, 11)
	 elseif yeGetString(obj.Rotation) == "down" then
	    lpcs.handlerSetOrigXY(npc, 0, 10)
	 else
	    lpcs.handlerSetOrigXY(npc, 0, 12)
	 end
	 lpcs.handlerRefresh(npc)
	 npc = Entity.wrapp(npc)
	 npc.canvas.Collision = 1
	 npc.char.name = obj.name:to_string()
	 npc.canvas.dialogue = obj.name:to_string()
	 npc.canvas.current = npc_idx
	 npc_idx = npc_idx + 1
      elseif layer_name:to_string() == "Entries" then
	 e_exits[j] = obj
	 j = j + 1
      elseif layer_name:to_string() == "Actionable" then
	 e_actionables[k] = obj
	 k = k + 1
      end
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
      if side == "up" then
	 y = y - 75
      elseif side == "down" then
	 y = y + ywRectH(rect) + 15
      elseif side == "left" then
	 x = x - 45
      else
	 x = x + ywRectW(rect) + 45
      end
   end
   if pj_pos then
      ylpcsHandlerSetPos(ent.pj, pj_pos)
      yeDestroy(pj_pos)
      pj_pos = nil
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

   ent.life_txt = ywCanvasNewTextExt(upCanvas.ent, 360, 10,
				     Entity.new_string("life: "),
				     "rgba: 255 255 255 255")
   ent.life_nb = ywCanvasNewTextExt(upCanvas.ent, 410, 10,
				    Entity.new_string(math.floor(phq.pj.life:to_int())),
				    "rgba: 255 255 255 255")
   reposeCam(ent)
end

function add_stat_hook(entity, stat, hook, val, comp_type)
   if entity.st_hooks == nil then
      entity.st_hooks = {}
   end
   entity.st_hooks[stat] = {}
   entity.st_hooks[stat].hook = ygGet(hook)
   entity.st_hooks[stat].val = val
   entity.st_hooks[stat].comp_type = comp_type
end

function create_phq(entity)
    local container = Container.init_entity(entity, "stacking")
    local ent = container.ent
    local scenePath = nil

    ent.move = {}
    ent.move.up_down = 0
    ent.move.left_right = 0
    ent.tid = 0
    tiled.setAssetPath("./");

    add_stat_hook(ent, "drunk", "FinishGame", 20, PHQ_SUP)
    add_stat_hook(ent, "life", "FinishGame", 0, PHQ_INF)
    print(ent.saved_data)
    yJrpgFightSetCombots("phq.combots")
    if ent.saved_data then
       print(ent.saved_data)
       scenePath = ent.saved_data.cur_scene_str
    else
       scenePath = Entity.new_string("house1")
    end
    Entity.new_func("phq_action", ent, "action")
    local mainCanvas = Canvas.new_entity(entity, "mainScreen")
    local upCanvas = Canvas.new_entity(entity, "upCanvas")
    ent["turn-length"] = 10000
    ent.entries = {}
    ent.background = "rgba: 127 127 127 255"
    ent.entries[0] = mainCanvas.ent
    ent.entries[1] = upCanvas.ent
    local ret = container:new_wid()
    ent.destroy = Entity.new_func("destroy_phq")
    ent.soundcallgirl = ySoundLoad("./callgirl.mp3")
    ent.pj = nil
    lpcs.createCaracterHandler(phq.pj, mainCanvas.ent, ent, "pj")
    load_scene(ent, scenePath:to_string(), 0)
    return ret
end
