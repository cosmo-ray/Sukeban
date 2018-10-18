local sleep_time = 0
local phq = Entity.wrapp(ygGet("phq"))
local dialogue = Entity.wrapp(ygGet("Dialogue"))
local dialogue_box = Entity.wrapp(ygGet("DialogueBox"))
local window_width = 800
local window_height = 600

function walkDoStep(wid, character)
   if yAnd(wid.tid:to_int(), 1) == 0 and
      (yuiAbs(yeGetInt(character.move.left_right)) == 1 or
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

function backToGame(wid)
   wid = Entity.wrapp(wid)
   if wid.isDialogue then
      wid = Entity.wrapp(yDialogueGetMain(wid))
      wid.main = nil
      if wid.src then
	 wid.src.isBlock = wid.isBlock
	 wid.src.block = wid.block
	 wid.src = nil
      end
   end
   local main = Entity.wrapp(ywCntWidgetFather(wid))

   if wid.oldTimer then
      main["turn-length"] = wid.oldTimer
   end
   ywCntPopLastEntry(main)
   main.current = 0
   return YEVE_ACTION
end

function backToGame2(wid)
   local main = Entity.wrapp(ywCntWidgetFather(wid))

   ywCntPopLastEntry(main)
   backToGame(wid)
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

function CombatEnd(wid, main, winner_id)
   local main = Entity.wrapp(main)
   local wid = Entity.wrapp(wid)
   local upcanvas = Canvas.wrapp(main.upCanvas)
   local winner = Entity.wrapp(yJrpgGetWinner(wid, winner_id))
   local looser = Entity.wrapp(yJrpgGetLooser(wid, winner_id))

   ySoundStop(main.soundcallgirl:to_int())
   if yLovePtrToNumber(winner) == 3 then
      yCallNextWidget(main:cent())
      return
   end
   upcanvas:remove(main.life_nb)
   main.life_nb = ywCanvasNewTextExt(upcanvas.ent, 410, 10,
				     Entity.new_string(math.floor(phq.pj.life:to_int())),
				     "rgba: 255 255 255 255")

   wid.main = nil
   backToGame(wid)
   return puushNewVictoryScreen(main, winner, looser)
   --print("end:", main, winner)
end


function StartFight(wid, eve)
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
   local usabel_items = Entity.new_array(phq.pj, "usable_items")
   local i = 0
   local inv = phq.pj.inventory
   while i < yeLen(inv) do
      local obj = phq.objects[yeGetKeyAt(inv, i)]
      if obj and obj.type:to_string() == "usable" then
	 usabel_items[yeGetKeyAt(inv, i)] = inv[i]
      end
      print(yeGetKeyAt(inv, i), inv[i])
      i  = i + 1
   end
   print("phq.pj.usable_items", phq.pj.usable_items)
   fWid.enemy = main.npcs[wid.npc_nb:to_int()].char
   print(fWid.enemy.max_life, fWid.enemy.name)
   fWid.enemy.life = fWid.enemy.max_life
   EndDialog(owid, eve, arg)
   ywPushNewWidget(main, fWid)
   return YEVE_ACTION
end

function addObject(main, character, objStr, nb)
   local obj = character.inventory[objStr]
   if obj then
      yeSetInt(obj, yeGetInt(obj) + nb)
   else
      character.inventory[objStr] = nb
   end
   return printMessage(main, obj, Entity.new_string("get " ..
						    math.floor(nb) ..
						    " " ..
						    objStr))
end

function recive(wid, eve, arg, objStr)
   wid = ywCntWidgetFather(yDialogueGetMain(wid))

   addObject(wid, phq.pj, yeGetString(objStr), 1)
end

function takeObject(main, actionable_obj, what, nb)
   actionable_obj = Entity.wrapp(actionable_obj)

   if actionable_obj.is_used then
      return YEVE_ACTION
   end
   addObject(main, phq.pj, yeGetString(what), yeGetInt(nb))
   actionable_obj.is_used = true
end

function pay(wid, eve, arg, cost, okAction, noDialogue)
   cost = yeGetInt(cost)
   if phq.pj.inventory.money >= cost then
      local money = phq.pj.inventory.money
      yeSetInt(money, money:to_int() - cost)
      return ywidAction(okAction, wid, eve, arg)
   end
   return dialogue["change-text"](wid, eve, arg, noDialogue)
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

function increase(wid, eve, arg, whatType, what, val)
   wid = ywCntWidgetFather(yDialogueGetMain(wid))
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
   increaseStat(ent, phq.pj, "drunk", 9, 100)
   increaseStat(ent, phq.pj, "life", 2, phq.pj.max_life:to_int())

   upcanvas:remove(ent.life_nb)
   ent.life_nb = ywCanvasNewTextExt(upcanvas.ent, 410, 10,
				    Entity.new_string(math.floor(phq.pj.life:to_int())),
                                    "rgba: 255 255 255 255")
   if phq.pj.drunk > 99 then
       ent.next = "phq:menus.end_txt"
       yCallNextWidget(ent:cent())
   end
   return printMessage(ent, obj, Entity.new_string("Glou Glou !"))
end

function GetDrink(wid, eve, arg)
   local ent = Entity.wrapp(ywCntWidgetFather(yDialogueGetMain(wid)))

   addObject(ent, phq.pj, "beer", 1)
   return EndDialog(wid, eve, arg)
end

function sleep(main, obj)
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
   phq.pj.life = phq.pj.max_life
   phq.pj.drunk = 0
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
      dialogueWid.name = npc.name
      ywPushNewWidget(entity, dialogueWid)
      return YEVE_ACTION
   end
   return YEVE_NOTHANDLE
end

function actionOrPrint(main, obj)
   obj = Entity.wrapp(obj)

   local condition = Entity.new_array()
   yeCreateString(yeGetString(obj.CheckOperation), condition);
   yePushBack(condition, obj.Check0);
   yePushBack(condition, obj.Check1);
   local ret = yeCheckCondition(condition)
   print(obj.Arg0, obj.CheckOperation, obj.Check0,
	 obj.Check1, obj.SucessAction, obj.Message,
	 obj.ActionArg0, ret, yeGetInt(ygGet(obj.Check0:to_string())))
   if ret then
      return yesCall(ygGet(obj.SucessAction:to_string()),
		     main, obj, obj.ActionArg0,
		     obj.ActionArg1, obj.ActionArg2)
   end
   return printMessage(main, obj, obj.Message)
end

function playSnake(wid, eve, arg, version)
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
      snake.die = Entity.new_func("backToGame2")
      snake.quit = Entity.new_func("backToGame2")
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
   vapp.die = Entity.new_func("backToGame")
   vapp.quit = Entity.new_func("backToGame")
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
