local tiled = Entity.wrapp(ygGet("tiled"))
local lpcs = Entity.wrapp(ygGet("lpcs"))
local phq = Entity.wrapp(ygGet("phq"))
local modPath = Entity.wrapp(ygGet("phq.$path")):to_string()
local checkColisisonF = Entity.new_func("CheckColision")
local npcs = Entity.wrapp(ygGet("phq.npcs"))
local dialogues = nil

function EndDialog(wid, eve, arg)
   wid = Entity.wrapp(yDialogueGetMain(wid))
   local main = Entity.wrapp(ywCntWidgetFather(wid))
   wid.main = nil
   if wid.src then
      wid.src.isBlock = wid.isBlock
      wid.src.block = wid.block
      print("wid.src.block:", wid.src.block)
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
				     Entity.new_string(phq.pj.life:to_int()),
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

function GetDrink(wid, eve, arg)
   print("this is the drink")
   local ent = Entity.wrapp(ywCntWidgetFather(yDialogueGetMain(wid)))
   local canvas = Canvas.wrapp(ent.mainScreen)
   phq.pj.drunk = phq.pj.drunk + 9

   canvas:remove(ent.drunk_bar1)
   ent.drunk_bar1 = canvas:new_rect(100, 10, "rgba: 0 255 30 255",
				    Pos.new(200 * phq.pj.drunk / 100 + 1, 15).ent).ent
   phq.pj.life = phq.pj.life + 2
   if phq.pj.life > phq.pj.max_life then
      phq.pj.life = phq.pj.max_life
   end
   canvas:remove(ent.life_nb)
   ent.life_nb = ywCanvasNewTextExt(canvas.ent, 410, 10,
				    Entity.new_string(phq.pj.life:to_int()),
                                    "rgba: 255 255 255 255")
   if phq.pj.drunk > 99 then
       ent.next = "phq:end_txt"
       yCallNextWidget(ent:cent())
   end
   EndDialog(wid, eve, arg)
   return YEVE_ACTION
end

function GetDrink2(wid, eve, arg)
   print("this is the drink")
   local ent = Entity.wrapp(ywCntWidgetFather(yDialogueGetMain(wid)))
   local canvas = Canvas.wrapp(ent.mainScreen)
   phq.pj.drunk = phq.pj.drunk + 18

   canvas:remove(ent.drunk_bar1)
   ent.drunk_bar1 = canvas:new_rect(100, 10, "rgba: 0 255 30 255",
				    Pos.new(200 * phq.pj.drunk / 100 + 1, 15).ent).ent
   phq.pj.life = phq.pj.life + 5
   canvas:remove(ent.life_nb)
   ent.life_nb = ywCanvasNewTextExt(canvas.ent, 410, 10,
				    Entity.new_string(phq.pj.life:to_int()),
				    "rgba: 255 255 255 255")
   if phq.pj.drunk > 99 then
       ent.next = "phq:end_txt"
       yCallNextWidget(ent:cent())
   end
   EndDialog(wid, eve, arg)
   return YEVE_ACTION
end

function init_phq(mod)
   Widget.new_subtype("phq", "create_phq")

   mod = Entity.wrapp(mod)
   mod.EndDialog = Entity.new_func("EndDialog")
   mod.StartFight = Entity.new_func("StartFight")
   mod.GetDrink = Entity.new_func("GetDrink")
   mod["GetDrink++"] = Entity.new_func("GetDrink2")
   mod.load_game = Entity.new_func("load_game")
end

function saveAndQuit(entity)
   print("can't save let's quit")
end

function load_game(entity)
   print("do the same move at the last part, and you're game will be load :)")
end

function CheckColision(canvasWid, pj)
   local pjPos = ylpcsHandePos(pj)
   local colRect = ywRectCreate(ywPosX(pjPos) + 7, ywPosY(pjPos) + 30,
			       20, 20)
   local col = ywCanvasNewCollisionsArrayWithRectangle(canvasWid, colRect)

   yeDestroy(colRect)
   col = Entity.wrapp(col)
   local i = 0
   while i < yeLen(col) do
      local obj = col[i]
      if yeGetIntAt(obj, "Collision") == 1 then
	 yeDestroy(col)
	 return true
      end
      i = i + 1
   end
   yeDestroy(col)
   return false
end

function phq_action(entity, eve, arg)
   entity = Entity.wrapp(entity)
   entity.tid = entity.tid + 1
   eve = Event.wrapp(eve)

   if yeGetInt(entity.current) == 1 then
      return NOTHANDLE
   end
   while eve:is_end() == false do
       if eve:type() == YKEY_DOWN then
	  if eve:key() == Y_ESC_KEY then
	     yCallNextWidget(entity:cent());
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
          elseif eve:key() == Y_SPACE_KEY or eve:key() ==Y_ENTER_KEY then
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
             local col = ywCanvasNewCollisionsArrayWithRectangle(entity.mainScreen, r:cent())
             col = Entity.wrapp(col)
             print("action !", Pos.wrapp(pjPos.ent):tostring(), Pos.wrapp(r.ent):tostring(), yeLen(col))
             local i = 0
             while i < yeLen(col) do
                local dialogue = col[i].dialogue
                print( CanvasObj.wrapp(col[i]):pos():tostring(), col[i].Collision, col[i].dialogue)
                if dialogue then
		   local dialogueWid = Entity.new_array()
		   local npc = entity.npcs[col[i].current:to_int()].char
		   local dialogue = dialogues[dialogue:to_string()]

		   print(dialogue)
		   if dialogue.dialogue then
		      yeCopy(dialogue, dialogueWid)
		      dialogueWid.src = dialogue
		   else
		      dialogueWid.dialogue = dialogue
		   end
		   dialogueWid["<type>"] = "dialogue-canvas"
		   dialogueWid.image = npc.image
		   dialogueWid.name = npc.name
		   dialogueWid.npc_nb = col[i].current
		   ywPushNewWidget(entity, dialogueWid)
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
    if CheckColision(entity.mainScreen, entity.pj)
    then
       mvPos:opposite()
       lpcs.handlerMove(entity.pj, mvPos.ent)
    end
    return YEVE_ACTION
end

function destroy_phq(entity)
   tiled.deinit()
   yeDestroy(dialogues)
   dialogues = nil
end

function create_phq(entity)
    local container = Container.init_entity(entity, "stacking")
    local ent = container.ent

    ent.move = {}
    ent.move.up_down = 0
    ent.move.left_right = 0
    ent.tid = 0
    dialogues = Entity.wrapp(ygFileToEnt(YJSON, ent.dialogues:to_string()))
    tiled.setAssetPath("./");
    Entity.new_func("phq_action", ent, "action")
    local mainCanvas = Canvas.new_entity(entity, "mainScreen")
    mainCanvas.ent.objs = {}
    ent["turn-length"] = 10000
    ent.entries = {}
    ent.background = "rgba: 127 127 127 255"
    ent.entries[0] = mainCanvas.ent
    local ret = container:new_wid()
    ent.destroy = Entity.new_func("destroy_phq")
    tiled.fileToCanvas("./bar1.json", mainCanvas.ent:cent())
    phq.pj.drunk = 0
    phq.pj.life = phq.pj.max_life
    ent.soundcallgirl = ySoundLoad("./callgirl.mp3")
    ent.drunk_txt = ywCanvasNewTextExt(mainCanvas.ent, 10, 10,
				       Entity.new_string("Puke bar: "),
				       "rgba: 255 255 255 255")
    ent.drunk_bar0 = mainCanvas:new_rect(100, 10, "rgba: 30 30 30 255",
					 Pos.new(200, 15).ent).ent
    ent.drunk_bar1 = mainCanvas:new_rect(100, 10, "rgba: 0 255 30 255",
					 Pos.new(200 * phq.pj.drunk / 100 + 1, 15).ent).ent

    ent.life_txt = ywCanvasNewTextExt(mainCanvas.ent, 360, 10,
				      Entity.new_string("life: "),
				      "rgba: 255 255 255 255")
    ent.life_nb = ywCanvasNewTextExt(mainCanvas.ent, 410, 10,
				     Entity.new_string(phq.pj.life:to_int()),
				     "rgba: 255 255 255 255")

    ent.pj = nil

    lpcs.createCaracterHandler(phq.pj, mainCanvas.ent, ent, "pj")
    lpcs.handlerRefresh(ent.pj)
    lpcs.handlerMove(ent.pj, Pos.new(200, 200).ent)
    lpcs.handlerSetOrigXY(ent.pj, 0, 10)
    lpcs.handlerRefresh(ent.pj)
    print(npcs, yeLen(npcs), yeGet(npcs, "robert"))
    local objects = ent.mainScreen.objects
    local i = 0
    ent.npcs = {}
    while i < yeLen(objects) do
       local obj = objects[i]
       local npc = lpcs.createCaracterHandler(npcs[obj.name:to_string()],
					       mainCanvas.ent, ent.npcs)
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
       print(npc.char.dialogue)
       npc.char.name = obj.name:to_string()
       npc.canvas.dialogue = obj.name:to_string()
       npc.canvas.current = i
       print(npc.canvas.dialogue)
       i = i + 1
    end
    return ret
end
