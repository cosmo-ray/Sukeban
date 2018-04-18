local tiled = Entity.wrapp(ygGet("tiled"))

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
    print("ACTION")
    while eve:is_end() == false do
        if eve:key() == Y_ESC_KEY then
            yCallNextWidget(entity:cent());
            return YEVE_ACTION
        end
        eve = eve:next()
    end
    return YEVE_ACTION
end

function create_phq(entity)
    local container = Container.init_entity(entity, "stack")
    local ent = container.ent

    tiled.setAssetPath("./");
    print(tiled);
    Entity.new_func("phq_action", ent, "action")
    local mainCanvas = Canvas.new_entity(entity, "mainScreen")
    mainCanvas.ent.objs = {}
    ent.entries = {}
    ent.entries[0] = mainCanvas.ent
    print("Create")
    local ret = container:new_wid()
    tiled.fileToCanvas("./bar1.json", mainCanvas.ent:cent())
    return ret
end
