local tiled = Entity.wrapp(ygGet("tiled"))
local lpcs = Entity.wrapp(ygGet("lpcs"))
local phq = Entity.wrapp(ygGet("phq"))
local modPath = Entity.wrapp(ygGet("phq.$path")):to_string()

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

function phq_action(entity, eve, arg)
    entity = Entity.wrapp(entity)
    eve = Event.wrapp(eve)
    while eve:is_end() == false do
       if eve:type() == YKEY_DOWN then
	  if eve:key() == Y_ESC_KEY then
	     yCallNextWidget(entity:cent());
	     return YEVE_ACTION
	  elseif eve:is_key_up() then
	     entity.move.up_down = -1
	  elseif eve:is_key_down() then
	     entity.move.up_down = 1	   
	  elseif eve:is_key_left() then
	     entity.move.left_right = -1
	  elseif eve:is_key_right() then
	     entity.move.left_right = 1
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
       end
       eve = eve:next()
    end
    lpcs.handelerMove(entity.pj, Pos.new(3 * entity.move.left_right,
					 3 * entity.move.up_down).ent)    
    return YEVE_ACTION
end

function create_phq(entity)
    local container = Container.init_entity(entity, "stack")
    local ent = container.ent

    ent.move = {}
    ent.move.up_down = 0
    ent.move.left_right = 0
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
    lpcs.handelerSetOrigXY(ent.pj, 2, 2)
    lpcs.handelerRefresh(ent.pj)
    return ret
end
