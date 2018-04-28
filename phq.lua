local tiled = Entity.wrapp(ygGet("tiled"))
local lpcs = Entity.wrapp(ygGet("lpcs"))
local phq = Entity.wrapp(ygGet("phq"))
local modPath = Entity.wrapp(ygGet("phq.$path")):to_string()
local checkColisisonF = Entity.new_func("CheckColision")
local npcs = Entity.wrapp(ygGet("phq.npcs"))
local dialogues = Entity.wrapp(ygGet("phq.dialogues"))

function EndDialog(wid, eve, arg)
   wid = Entity.wrapp(yDialogueGetMain(wid))
   local main = Entity.wrapp(ywCntWidgetFather(wid))
   wid.main = nil
   ywCntPopLastEntry(main)
   main.current = 0
   return YEVE_ACTION
end

function CombatEnd(wid, main, winner)
   local main = Entity.wrapp(main)
   local wid = Entity.wrapp(wid)
   wid.main = nil
   ywCntPopLastEntry(main)
   main.current = 0
   --print("end:", main, winner)
end

function StartFight(wid, eve, arg)
   print("this is the kaboum")
   local main = Entity.wrapp(ywCntWidgetFather(yDialogueGetMain(wid)))
   local fWid = Entity.new_array()

   EndDialog(wid, eve, arg)
   fWid["<type>"] = "jrpg-fight"
   fWid.endCallback = Entity.new_func("CombatEnd")
   fWid.endCallbackArg = main
   print(fWid.endCallbackArg:cent())
   ywPushNewWidget(main, fWid)
   print("2:", fWid.endCallbackArg:cent())
   return YEVE_ACTION
end

function GetDrink(wid, eve, arg)
   print("this is the drink")
   EndDialog(wid, eve, arg)
   return YEVE_ACTION
end

function init_phq(mod)
   Widget.new_subtype("phq", "create_phq")

   mod = Entity.wrapp(mod)
   mod.EndDialog = Entity.new_func("EndDialog")
   mod.StartFight = Entity.new_func("StartFight")
   mod.GetDrink = Entity.new_func("GetDrink")
   mod.load_game = Entity.new_func("load_game")
end

function saveAndQuit(entity)
   print("can't save let's quit")
end

function load_game(entity)
   print("do the same move at the last part, and you're game will be load :)")
end

function CheckColision(entity, obj, guy)
   if ywCanvasObjectsCheckColisions(guy, obj) then
      if yeGetIntAt(obj, "Collision") == 1 and
	 ywCanvasObjectsCheckColisions(obj, guy) then
	 return Y_TRUE
      end
   end
   return Y_FALSE
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
          elseif eve:key() == Y_SPACE_KEY then
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
		   dialogueWid["<type>"] = "dialogue-canvas"
		   dialogueWid.dialogue = dialogues[dialogue:to_int()]
		   dialogueWid.image = col[i].image
		   ywPushNewWidget(entity, dialogueWid)
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
    if (yuiAbs(entity.move.left_right:to_int()) == 1 or yuiAbs(entity.move.up_down:to_int()) == 1) and
       yAnd(entity.tid:to_int(), 3) == 0 then
       handlerNextStep(entity.pj)
       lpcs.handelerRefresh(entity.pj)
    end
    local mvPos = Pos.new(3 * entity.move.left_right, 3 * entity.move.up_down)
    lpcs.handelerMove(entity.pj, mvPos.ent)
    if ywCanvasCheckCollisions(entity.mainScreen,
                                 entity.pj.canvas,
                                 checkColisisonF) == 1
    then
       mvPos:opposite()
       lpcs.handelerMove(entity.pj, mvPos.ent)
    end
    return YEVE_ACTION
end

function handlerNextStep(handler)
        local linelength = {7, 7, 7, 7, 8, 8, 8, 8, 9, 9, 9, 9, 6, 6, 6, 6, 13, 13, 13, 13, 6}
        if handler.x:to_int() < (linelength[handler.y:to_int()] - 1) then
                handler.x = (handler.x:to_int() + 1)
        else
                handler.x = 0
        end
end

function create_phq(entity)
    local container = Container.init_entity(entity, "stacking")
    local ent = container.ent

    ent.move = {}
    ent.move.up_down = 0
    ent.move.left_right = 0
    ent.tid = 0
    tiled.setAssetPath("./");
    print(tiled);
    Entity.new_func("phq_action", ent, "action")
    local mainCanvas = Canvas.new_entity(entity, "mainScreen")
    mainCanvas.ent.objs = {}
    ent["turn-length"] = 10000
    ent.entries = {}
    ent.background = "rgba: 127 127 127 255"
    ent.entries[0] = mainCanvas.ent
    local ret = container:new_wid()
    tiled.fileToCanvas("./bar1.json", mainCanvas.ent:cent())
    lpcs.createCaracterHandeler(phq.pj, mainCanvas.ent, ent, "pj")
    lpcs.handelerRefresh(ent.pj)
    lpcs.handelerMove(ent.pj, Pos.new(200, 200).ent)
    lpcs.handelerSetOrigXY(ent.pj, 0, 10)
    lpcs.handelerRefresh(ent.pj)
    print(npcs, yeLen(npcs), yeGet(npcs, "robert"))
    local objects = ent.mainScreen.objects
    local i = 0
    ent.npcs = {}
    while i < yeLen(objects) do
       local obj = objects[i]
       ent.npcs[i] = {}
       local npc = lpcs.createCaracterHandeler(npcs[obj.name:to_string()], mainCanvas.ent, ent.npcs)
       --print("obj (", i, "):", obj, npcs[obj.name:to_string()], obj.rect)
       local pos = Pos.new_copy(obj.rect)
       pos:sub(20, 50)
       lpcs.handelerMove(npc, pos.ent)
       print("-------")
       lpcs.handelerSetOrigXY(npc, 0, 10)
       lpcs.handelerRefresh(npc)
       npc = Entity.wrapp(npc)
       npc.canvas.Collision = 1
       print(npc.char.dialogue)
       npc.canvas.dialogue = npc.char.dialogue
       npc.canvas.image = npc.char.image
       print(npc.canvas.dialogue)
       i = i + 1
    end
    return ret
end
