local tiled = Entity.wrapp(ygGet("tiled"))
local lpcs = Entity.wrapp(ygGet("lpcs"))
local phq = Entity.wrapp(ygGet("phq"))
local modPath = Entity.wrapp(ygGet("phq.$path")):to_string()
local npcs = Entity.wrapp(ygGet("phq.npcs"))
local scenes = Entity.wrapp(ygGet("phq.scenes"))
local dialogues = nil
local window_width = 800
local window_height = 600

local NO_COLISION = 0
local NORMAL_COLISION = 1
local CHANGE_SCENE_COLISION = 2

local function reposScreenInfo(ent, x0, y0)
   ywCanvasObjSetPos(ent.drunk_txt, x0 + 10, y0 + 10)
   ywCanvasObjSetPos(ent.drunk_bar0, x0 + 100, y0 + 10)
   ywCanvasObjSetPos(ent.drunk_bar1, x0 + 100, y0 + 10)
   ywCanvasObjSetPos(ent.life_txt, x0 + 360, y0 + 10)
   ywCanvasObjSetPos(ent.life_nb, x0 + 410, y0 + 10)
end

local function reposeCam(main)
   local canvas = main.mainScreen
   local pjPos = Pos.wrapp(ylpcsHandePos(main.pj))
   local x0 = pjPos:x() - window_width / 2
   local y0 = pjPos:y() - window_height / 2

   ywPosSet(canvas.cam, x0, y0)
   reposScreenInfo(main, x0, y0)
end

function backToGame(wid)
   local main = Entity.wrapp(ywCntWidgetFather(wid))   
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
   local ent = Entity.wrapp(ywCntWidgetFather(yDialogueGetMain(wid)))
   local canvas = Canvas.wrapp(ent.mainScreen)
   phq.pj.drunk = phq.pj.drunk + 9

   print(phq.pj.drunk, ent.drunk_bar1:cent())
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

function CheckColisionTryChangeScene(main, cur_scene, direction)
   if cur_scene.out and cur_scene.out[direction] then
      local dir_info = cur_scene.out[direction]
      local nextSceneTxt = nil
      if dir_info.to then
	 nextSceneTxt = dir_info.to:to_string()
      else
	 nextSceneTxt = dir_info:to_string()
      end
      local nextScene = scenes[nextSceneTxt]

      if nextScene == nil then
	 nextScene = ygGet(nextSceneTxt)
      end
      load_scene(main, nextScene, yeGetIntAt(dir_info, "entry"))
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
	 local nextScene = scenes[nextSceneTxt]
	 print(nextScene)
	 if nextScene == nil then
	    nextScene = ygGet(nextSceneTxt)
	 end
	 load_scene(main, nextScene, yeGetInt(main.exits[i].entry))
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

function pushMainMenu(main)
   local mn = Menu.new_entity()

   mn:push("back to game", Entity.new_func("backToGame"))
   mn:push("save game")
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

   if yeGetInt(entity.current) == 1 then
      return NOTHANDLE
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
                if dialogue and dialogues[dialogue:to_string()] then
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
   yeDestroy(dialogues)
   dialogues = nil
   ent.current = 0
   ent.entries = nil
end

function load_scene(ent, scene, entryIdx)
   local mainCanvas = Canvas.wrapp(ent.mainScreen)
   local x = 0
   local y = 0
   scene = Entity.wrapp(scene)

   -- clean old stuff :(
   mainCanvas.ent.objs = {}
   mainCanvas.ent.objects = {}
   tiled.fileToCanvas(scene.tiled:to_string(), mainCanvas.ent:cent())
   dialogues = Entity.wrapp(ygFileToEnt(YJSON, yeGetString(scene.dialogues)))
   mainCanvas.ent.cam = Pos.new(0, 0).ent
   -- Pj info:
   local objects = ent.mainScreen.objects
   local i = 0
   local npc_idx = 0
   local j = 0
   ent.npcs = {}
   ent.exits = {}
   ent.cur_scene = scene
   local e_npcs = ent.npcs
   local e_exits = ent.exits
   while i < yeLen(objects) do
      local obj = objects[i]
      local layer_name = obj.layer_name
      if layer_name:to_string() == "NPC" then
	 local npc = lpcs.createCaracterHandler(npcs[obj.name:to_string()],
						mainCanvas.ent, e_npcs)
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
      end
      i = i + 1
   end

   print("entryIdx !!!!", entryIdx)
   if entryIdx < 0 then
      x = 300
      y = 200
   else
      local rect = e_exits[entryIdx].rect
      local side = e_exits[entryIdx].side:to_string()
      x = ywRectX(rect)
      y = ywRectY(rect)
      print(x, y)
      print(rect, side)
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
   ylpcsHandlerSetPos(ent.pj, Pos.new(x, y).ent)
   lpcs.handlerSetOrigXY(ent.pj, 0, 10)
   lpcs.handlerRefresh(ent.pj)
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
   reposeCam(ent)
end
   
function create_phq(entity)
    local container = Container.init_entity(entity, "stacking")
    local ent = container.ent
    local scene = Entity.wrapp(ygGet(ent.scene:to_string()))

    ent.move = {}
    ent.move.up_down = 0
    ent.move.left_right = 0
    ent.tid = 0
    tiled.setAssetPath("./");
    Entity.new_func("phq_action", ent, "action")
    local mainCanvas = Canvas.new_entity(entity, "mainScreen")
    ent["turn-length"] = 10000
    ent.entries = {}
    ent.background = "rgba: 127 127 127 255"
    ent.entries[0] = mainCanvas.ent
    local ret = container:new_wid()
    ent.destroy = Entity.new_func("destroy_phq")
    phq.pj.drunk = 0
    phq.pj.life = phq.pj.max_life
    ent.soundcallgirl = ySoundLoad("./callgirl.mp3")
    ent.pj = nil
    lpcs.createCaracterHandler(phq.pj, mainCanvas.ent, ent, "pj")
    load_scene(ent, scene, 0)
    return ret
end
