local sleep_time = 0
local phq = Entity.wrapp(ygGet("phq"))
local dialogue = Entity.wrapp(ygGet("Dialogue"))
local dialogue_box = Entity.wrapp(ygGet("DialogueBox"))
local window_width = 800
local window_height = 600
fight_script = nil

local use_time_point_action = Entity.new_string("phq.use_time_point")

function use_time_point(box)
   if phq.env.time_point:to_int() == 0 then
      printMessage(main_boxget, nil, "Not enough time point")
      return Y_FALSE
   end

   box = Entity.wrapp(box)
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

function quest_update(original, copy, arg)
   local main = yeGet(arg, 0)
   local quest_name = yeGet(arg, 1)
   quest_name = yeGetString(quest_name)
   local quest = quests_info[quest_name]
   local stalk_sart = yeGetIntAt(quest, "stalk_sart")
   local rewards = quest.rewards
   local r_idx = yeGetInt(original)
   local reward = yeGetIntAt(rewards, r_idx)

   print("changed:", Entity.wrapp(original), Entity.wrapp(copy), quest_name)
   print("reward:", reward)
   if reward ~= 0 then
      increaseStat(main, phq.pj, "xp", reward)
   end
end

function walkDoStep(wid, character)
   if (yuiAbs(yeGetInt(character.move.left_right)) == 1 or
       yuiAbs(yeGetInt(character.move.up_down)) == 1)  then
      ylpcsHandlerNextStep(character)
      ylpcsHandlerRefresh(character)
   end
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

function backToGame(wid)
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

   if (yIsNil(phq_action_timer) == false) then
      yeSetInt(phq_action_timer, os.time())
      phq_action_timer = nil
   end

   if yeGetInt(wid.in_subcontained) == 1 then
      wid = Entity.wrapp(ywCntWidgetFather(wid))
   end
   local main = Entity.wrapp(ywCntWidgetFather(wid))

   if wid.oldTimer then
      main["turn-length"] = wid.oldTimer
   end
   local nb_layers = yeGetInt(wid.nb_layers)
   while nb_layers > 1 do
      ywCntPopLastEntry(main)
      nb_layers = nb_layers - 1
   end
   ywCntPopLastEntry(main)
   main.current = 0
   main.pj.move.up_down = 0
   main.pj.move.left_right = 0
   return YEVE_ACTION
end

function CombatEnd(wid, main, winner_id)
   local main = main_widget
   local wid = Entity.wrapp(wid)
   local upcanvas = Canvas.wrapp(main.upCanvas)
   local winner = Entity.wrapp(yJrpgGetWinner(wid, winner_id))
   local looser = Entity.wrapp(yJrpgGetLooser(wid, winner_id))

   ySoundStop(main.soundcallgirl)
   wid.main = nil
   if yLovePtrToNumber(winner_id) == 3 then
      backToGame(wid)
      yCallNextWidget(main:cent())
      return
   end
   upcanvas:remove(main.life_nb)
   main.life_nb = ywCanvasNewTextExt(upcanvas.ent, 410, 10,
				     Entity.new_string(math.floor(phq.pj.life:to_int())),
				     "rgba: 255 255 255 255")

   if yeGetString(fight_script) == "CombatDialogueNext" then
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
   if yIsNil(npc.name) then
      npc.name = enemy_type
   end
   if yIsNil(npc.max_life) then
      npc.max_life = 1
   end
   npc.life = npc.max_life
   return npc
end

function StartFight(wid, eve, enemy_type, script)
   local main = getMainWid(wid)
   local fWid = Entity.new_array()
   local npc = nil
   --ySoundPlayLoop(main.soundcallgirl:to_int())

   if (yIsNil(enemy_type)) then
      local wid = yDialogueGetMain(wid)
      wid = Entity.wrapp(wid)
      npc = main.npcs[wid.npc_nb:to_int()].char
      npc = npcDefaultInit(npc, "???")
   else
      if yeType(enemy_type) == YARRAY then
	 local i = 0
	 npc = Entity.new_array()
	 while i < yeLen(enemy_type) do
	    local enemy_type = yeGet(enemy_type, i)
	    print("npc ", i , ": ", yeGetString(enemy_type))
	    npc[i] = npcs[yeGetString(enemy_type)]
	    npc[i] = npcDefaultInit(npc[i], enemy_type)
	    print("npc: ", npc[i])
	    i = i + 1
	 end
      else
	 npc = npcs[yeGetString(enemy_type)]
	 npc = npcDefaultInit(npc, enemy_type)
      end

   end

   if yIsNil(script) == false then
      if (yeType(script)) == YARRAY then
	 fight_script = script[0]
      else
	 fight_script = script
      end
   end
   fWid["<type>"] = "jrpg-fight"
   fWid.endCallback = Entity.new_func("CombatEnd")
   fWid.ychar_start = 80
   fWid.endCallbackArg = main
   fWid.player = phq.pj
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
   if yeGetString(fight_script) == "CombatDialogueNext" then
      dialogue.gotoNext(wid, eve)
   elseif yeGetString(fight_script) == "RemoveEnemy" then
      lpcs.handlerNullify(script[1])
      yeRemoveChild(main.enemies, script[1])
   else
      backToGame(wid, eve)
   end
   print("NEW WID !", main:cent(), fWid:cent())
   ywPushNewWidget(main, fWid)
   return YEVE_ACTION
end

function addObject(main, character, objStr, nb)
   local obj = character.inventory[objStr]
   local msg = "get "

   if obj then
      local nb = yeGetInt(obj) + nb
      if nb == 0 then
	 character.inventory[objStr] = nil
      else
	 yeSetInt(obj, nb)
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
   return printMessage(main, obj, Entity.new_string(msg ..
						    math.floor(nb) ..
						    " " ..
						    objStr))
end

function recive(wid, eve, objStr, nb)
   wid = ywCntWidgetFather(yDialogueGetMain(wid))
   nb = yeGetInt(nb)
   if nb == 0 then
      nb = 1
   end
   addObject(wid, phq.pj, yeGetString(objStr), nb)
end

function remove(wid, eve, objStr, nb)
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

function pay(wid, eve, cost, okAction, noDialogue)
   cost = yeGetInt(cost)
   if phq.pj.inventory.money >= cost then
      local money = phq.pj.inventory.money
      yeSetInt(money, money:to_int() - cost)
      return ywidAction(okAction, wid, eve)
   end
   return dialogue["change-text"](wid, eve, noDialogue)
end

function increaseStat(wid, stats_container, stat, nb, max_min)
   local s = stats_container[stat]
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

function increase(wid, eve, whatType, what, val)
   wid = ywCntWidgetFather(yDialogueGetMain(wid))
   if yeType(what) == YINT then
      val = what
      what = whatType
      return increaseStat(wid, phq.pj, yeGetString(what), yeGetInt(val))
   end
   local stat_container = phq.pj[yeGetString(whatType)]
   local what = yeGetString(what)
   if stat_container[what] == nil then
      stat_container[what] = 0
   end
   return increaseStat(wid, stat_container, what, yeGetInt(val))
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

-- in fact, this function do 2 things: adancing time and start sleep animation
function advance_time(main)
   npcAdvenceTime()
   if phq.env.time:to_string() == "night" then
      phq.env.time = "morning"
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
   phq.env.time_point = 1
   main = Entity.wrapp(main)
   pj_pos = ylpcsHandePos(main.pj)
   yeIncrRef(pj_pos)
   load_scene(main, main.cur_scene_str:to_string(), -1)
   main.sleep = 1
   main.require_ret = 1
end

function sleep(main, obj)
   advance_time(main)
   phq.pj.life = phq.pj.max_life
   phq.pj.drunk = 0
end

function printMessage(main, obj, msg)
   local txt = yLuaString(msg)
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
      ywPushNewWidget(entity, dialogueWid)
      return YEVE_ACTION
   end
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

   if (yeGetInt(ygGet("phq.quests.hightscores.lvl"))) > 1 then
      return 0
   end

   if (yeGetInt(ygGet("phq.quests.hightscores.lvl"))) > 0 then
      if (yeGetInt(lvl) == 0) then
	 return 0
      end
      lvl_check = 1
   end

   while i < lvl_check do
      local j = 0
      while j < yeLen(hs) do
	 chs = yeGet(hs, j)
	 if phq.pj.name:to_string() == yeGetKeyAt(hs[j], i) then
	    phq.quests.hightscores = {}
	    if lvl_check < 3 then
	       phq.quests.hightscores.lvl = 2
	    else
	       phq.quests.hightscores.lvl = 1
	    end
	    --["setInt", "phq.quests.hightscore.lvl", 1],
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
   hgw.action = Entity.new_func("backToGameOnEnter")
   ywPushNewWidget(main, hgw)
   return YEVE_ACTION
end

function playSnake(wid, eve, version)
   local wid = Entity.wrapp(wid)
   local main = nil

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
      snake.die = Entity.new_func("showHightScore")
      snake.quit = Entity.new_func("showHightScore")
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
   return YEVE_ACTION
end

function changeScene(wid, eve, scene, entry)
   local main = getMainWid(wid)
   load_scene(main, yeGetString(scene), yeGetInt(entry))
   backToGame(wid)
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
   ast_shoot.hightscore_path = "phq.hightscores.ast-shoot"
   ast_shoot.die = Entity.new_func("showHightScore")
   ast_shoot.quit = Entity.new_func("backToGame")
   ast_shoot.oldTimer = main["turn-length"]
   main["turn-length"] = 40000
   ywPushNewWidget(main, ast_shoot)
   return YEVE_ACTION
end

function playTetris(wid)
   local wid = Entity.wrapp(wid)
   local main = nil

   print("play T !!!!")
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

function phs_start(wid)
   local m = main_widget

   local t = Entity.new_array()
   t["<type>"] = "phs"
   t.resources = ygGet("phs.resources")
   ywPushNewWidget(m, t)
   return YEVE_ACTION
end

function play(wid, eve, game, timer)
   local wid = Entity.wrapp(wid)
   local main = getMainWid(wid)

   print("play !!!!", eve, game, yeGetInt(timer))

   ywCntPopLastEntry(main)
   local t = Entity.new_array()

   t["<type>"] = game
   t.die = Entity.new_func("backToGame")
   t.quit = Entity.new_func("backToGame")
   t.oldTimer = main["turn-length"]
   main["turn-length"] = timer
   ywPushNewWidget(main, t)
   return YEVE_ACTION
end

function playVapp(wid)
   local wid = Entity.wrapp(wid)
   local main = nil

   if wid.isDialogue then
      wid = Entity.wrapp(yDialogueGetMain(wid))
   end
   main = Entity.wrapp(ywCntWidgetFather(wid))

   ywCntPopLastEntry(main)
   local vapp = Entity.new_array()

   vapp["<type>"] = "vapz"
   vapp.resources = "vapp:resources.map"
   vapp.die = Entity.new_func("showHightScore")
   vapp.quit = Entity.new_func("backToGame")
   vapp.hightscore_path = "phq.hightscores.vapp"
   vapp.oldTimer = main["turn-length"]
   main["turn-length"] = 150000
   ywPushNewWidget(main, vapp)
   return YEVE_ACTION
end

function doSleep(ent, upCanvas)
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
