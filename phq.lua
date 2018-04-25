local tiled = Entity.wrapp(ygGet("tiled"))
local lpcs = Entity.wrapp(ygGet("lpcs"))
local phq = Entity.wrapp(ygGet("phq"))
local modPath = Entity.wrapp(ygGet("phq.$path")):to_string()
local checkColisisonF = Entity.new_func("CheckColision")

function init_phq(mod)
   Widget.new_subtype("phq", "create_phq")

   Entity.wrapp(mod).load_game = Entity.new_func("load_game")
end

function saveAndQuit(entity)
   print("save and quit")
end

function load_game(entity)
   print("loading")
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
    local container = Container.init_entity(entity, "stack")
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
    return ret
end
