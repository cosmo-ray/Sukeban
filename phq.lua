local near_door = 1
local near_bed = 2
local near_radio = 4
local near_fridge = 8
local near_wc = 16
local near_shower = 32

function init_phq(mod)
   Widget.new_subtype("phq", "create_phq")

   Entity.wrapp(mod).load_game = Entity.new_func("load_game")
   Entity.wrapp(mod).fight_time = Entity.new_func("swapToFight")
   Entity.wrapp(mod).house_time = Entity.new_func("swapToHouse")
   Entity.wrapp(mod).shop_time = Entity.new_func("swapToShop")
   Entity.wrapp(mod).attack = Entity.new_func("phqFSAttackGuy")
end

function saveAndQuit(entity)
   local mainMenu = Entity.wrapp(ywCntWidgetFather(entity))
   local main = Entity.wrapp(ywCntWidgetFather(mainMenu:cent()))
   local saved_data = Entity.new_array()

   saved_data.guy = main.guy
   saved_data.guy.canvas = nil
   saved_data.has_pyjama = main.has_pyjama
   saved_data.has_dress = main.has_dress
   saved_data.cur_objs = main.cur_objs
   ygEntToFile(YJSON, "./saved.json", saved_data:cent())
   yCallNextWidget(main:cent());
   return YEVE_ACTION
end

function load_game(entity)
   local game = ygGet("phq.game")
   local ent = ygFileToEnt(YJSON, "./saved.json")
   Entity.wrapp(game).saved_data = ent
   yeDestroy(ent)
   yCallNextWidget(entity);
end

function display_text_timer(main, anim)
   anim = Entity.wrapp(anim)
   main = Entity.wrapp(main)

   anim.animation_frame = anim.animation_frame + 1
   if anim.animation_frame > 30 then
      Canvas.wrapp(anim.wid):remove(anim.text)
      endAnimation(main, "txt_anim")
      return Y_FALSE
   end
   return Y_TRUE
end

function display_text(main, txt, x, y)
   local canvas = Canvas.wrapp(main.entries[0])

   local anim = startAnimation(main:cent(),
			       Entity.new_func("display_text_timer"), "txt_anim")
   anim.text = canvas:new_text(x, y, Entity.new_string(txt)):cent()
   anim.wid = canvas.ent
end

function CheckColision(entity, obj, guy)
    if ywCanvasObjectsCheckColisions(obj, guy) then
        return Y_TRUE
    end
    return Y_FALSE
end

function phq_action(entity, eve, arg)
   entity = Entity.wrapp(entity)
   eve = Event.wrapp(eve)
   local move = entity.move
   local guy = entity.guy
   local return_not_handle = false


   while eve:is_end() == false do
        if eve:type() == YKEY_DOWN then
	        if eve:key() == Y_ESC_KEY then
	            yCallNextWidget(entity:cent());
	            return YEVE_ACTION
            elseif eve:key() == Y_W_KEY or eve:key() == Y_Z_KEY then
                move.up_down = -1
                guy.current_id = 1
            elseif eve:key() == Y_S_KEY then
                move.up_down = 1
                guy.current_id = 0
            elseif eve:key() == Y_A_KEY or eve:key() == Y_Q_KEY then
                move.left_right = -1
                guy.current_id = 2
            elseif eve:key() == Y_D_KEY then
                move.left_right = 1
                guy.current_id = 3
            elseif eve:key() == Y_UP_KEY or eve:key() == Y_DOWN_KEY then
	            return_not_handle = true
            elseif eve:key() == Y_LEFT_KEY then
                if guy.movable:to_int() == 0 then
                    move.left_right = -1
                end
            elseif eve:key() == Y_RIGHT_KEY then
                if guy.movable:to_int() == 0 then
                    move.left_right = 1
                end
            end
        elseif eve:type() == YKEY_UP then
            if eve:is_key_up() or eve:is_key_down() or eve:key() == Y_Z_KEY
                then move.up_down = 0
            elseif eve:is_key_left() or eve:is_key_right() or eve:key() == Y_Q_KEY then
	            move.left_right = 0
            end
            entity.step = 0
        end
      eve = eve:next()
   end
   doAnimation(entity, "txt_anim")
   if guy.movable:to_int() == 1 and (move.up_down ~= Entity.new_int(0) or

				     move.left_right ~= Entity.new_int(0)) then

      if (entity.step:to_int() % 5 == 0) then
	 ywCanvasObjSetResourceId(guy.canvas:cent(), (((entity.step:to_int() / 5) % 4) * 4
						      + (guy.current_id)))
      end
      entity.step = entity.step + 1
      CanvasObj.wrapp(entity.guy.canvas):move(Pos.new(5 * move.left_right,
						      5 * move.up_down))
      if ywCanvasCheckCollisions(entity.mainScreen:cent(),
				 entity.guy.canvas:cent(),
				 Entity.new_func("CheckColision"):cent()) == 1
      then
	 CanvasObj.wrapp(entity.guy.canvas):move(Pos.new(-5 * move.left_right,
							 -5 * move.up_down))
      end
      if return_not_handle then
	 return YEVE_NOTHANDLE
      end
      return YEVE_ACTION
   end
   if doAnimation(entity, "cur_anim") then
      return YEVE_ACTION
   end
   if entity.invScreen:cent() == entity.entries[0]:cent() then

      if move.up_down:to_int() ~= 0 then
	 move.left_right = move.up_down * 4
	 move.up_down = 0
      end

      if move.left_right:to_int() ~= 0 then
	 shoop_cursor_move(entity, entity.invScreen, move.left_right:to_int())
	 move.left_right = 0
	 return YEVE_ACTION
      end
   end
   return YEVE_NOTHANDLE
end

function sleep(entity)
   local mainMenu = Entity.wrapp(ywCntWidgetFather(entity))
   local main = Entity.wrapp(ywCntWidgetFather(mainMenu:cent()))

   statAdd(main.guy, "energy", main.bed.stat.energy)
   statAdd(main.guy, "hygien", -2)
   statAdd(main.guy, "hunger", -5)
   statAdd(main.guy, "bladder", -2)
   statAdd(main.guy, "fun", -2)

end

function wash_yourself(entity)
    local mainMenu = Entity.wrapp(ywCntWidgetFather(entity))
    local main = Entity.wrapp(ywCntWidgetFather(mainMenu:cent()))

    statAdd(main.guy, "hygien", main.shower.stat.hygien)
    statAdd(main.guy, "hunger", -2)
    statAdd(main.guy, "bladder", -2)
    statAdd(main.guy, "energy", -2)
    statAdd(main.guy, "fun", -2)
 end

function have_fun(entity)
    local mainMenu = Entity.wrapp(ywCntWidgetFather(entity))
    local main = Entity.wrapp(ywCntWidgetFather(mainMenu:cent()))

    statAdd(main.guy, "fun", main.radio.stat.fun)
    statAdd(main.guy, "hygien", -2)
    statAdd(main.guy, "hunger", -2)
    statAdd(main.guy, "bladder", -2)
    statAdd(main.guy, "energy", -2)
    ySoundPlayLoop(Entity.wrapp(main).soundpft:to_int())

end

function eat(entity)
    local mainMenu = Entity.wrapp(ywCntWidgetFather(entity))
    local main = Entity.wrapp(ywCntWidgetFather(mainMenu:cent()))

    statAdd(main.guy, "hunger", main.fridge.stat.food)
    statAdd(main.guy, "hygien", -2)
    statAdd(main.guy, "bladder", -2)
    statAdd(main.guy, "energy", -2)
    statAdd(main.guy, "fun", -2)
end

function go_to_the_toilet(entity)
    local mainMenu = Entity.wrapp(ywCntWidgetFather(entity))
    local main = Entity.wrapp(ywCntWidgetFather(mainMenu:cent()))

    statAdd(main.guy, "bladder", main.wc.stat.bladder)
    statAdd(main.guy, "hygien", -2)
    statAdd(main.guy, "hunger", -2)
    statAdd(main.guy, "energy", -2)
    statAdd(main.guy, "fun", -2)
end

function canvasCenter(canvasEntity)
   local bed = CanvasObj.wrapp(canvasEntity)
   local b_pos = Pos.new(bed:pos():x() + (bed:size():x() / 2),
			 bed:pos():y() + (bed:size():y() / 2))

   return b_pos
end

function duistanceObjs(obj0, obj1)
   local obj0_p = canvasCenter(obj0)
   local obj1_p = canvasCenter(obj1)
   local seg_x = obj1_p:x() - obj0_p:x()
   local seg_y = obj1_p:y() - obj0_p:y()

   return math.sqrt((seg_x * seg_x) + (seg_y * seg_y))
end

function getNearObjectMask(main)
   local guy_can = main.guy.canvas
   local ret = 0
   local b_pos = canvasCenter(main.bed)
   local g_pos = canvasCenter(main.guy.canvas)

   if duistanceObjs(guy_can, main.bed) < 90 then
      ret = yOr(ret, near_bed)
   end
   if duistanceObjs(guy_can, main.door) < 90 then
      ret = yOr(ret, near_door)
   end
   if duistanceObjs(guy_can, main.wc) < 90 then
      ret = yOr(ret, near_wc)
   end
   if duistanceObjs(guy_can, main.radio) < 90 then
      ret = yOr(ret, near_radio)
   end
   if duistanceObjs(guy_can, main.fridge) < 90 then
      ret = yOr(ret, near_fridge)
   end
   if duistanceObjs(guy_can, main.shower) < 90 then
      ret = yOr(ret, near_shower)
   end
   --print(g_pos:to_string(), b_pos:to_string(), duistanceObjs(main.bed, guy_can))
   return ret
end

function updateMainMenu2(main, mainMenu)
   local mask = getNearObjectMask(main)
   if main.near_objects_mask:to_int() == mask then
      return
   end
   main.near_objects_mask = mask
   cleanMenuAction(mainMenu)
   updateMainMenu(main, mainMenu)
end

function updateMainMenu(main, mainMenu)

   if (yAnd(mask, near_door) ~= 0) then
      setMenuAction(mainMenu, "go to work", "phq.fight_time")
      setMenuAction(mainMenu, "go shoping", "phq.shop_time")
   end
   if (yAnd(mask, near_wc) ~= 0) then
      setMenuAction(mainMenu, "go to the toilet",
		    Entity.new_func("go_to_the_toilet"))
   end
   setMenuAction(mainMenu, "quit", "callNext")
   setMenuAction(mainMenu, "save and quit", Entity.new_func("saveAndQuit"))
end

function swapToHouse(entity)
    local mainMenu = Entity.wrapp(ywCntWidgetFather(entity))
    local main = ywCntWidgetFather(mainMenu:cent())

    Entity.wrapp(entity).next = Entity.wrapp(main).next
    ywReplaceEntry(main, 0, Entity.wrapp(main).mainScreen:cent())
    main = Entity.wrapp(main)
    main.guy.movable = 1
    if main.currentmusic ~= main.soundhouse then
        ySoundPlayLoop(main.soundhouse:to_int())
        main.currentmusic = main.soundhouse:to_int()
    end
    cleanMenuAction(mainMenu)
    updateMainMenu(main, mainMenu)
    return YEVE_ACTION
end

function add_furniture(main, furn_type, t, rect, path, price, name)
   local ft = main[furn_type][t]
   local ftlen = ft:len()

   ft[ftlen] = {}
   ft[ftlen].rect = rect:cent()
   ft[ftlen].path = path
   ft[ftlen].price = price
   ft[ftlen].name = name
   return ft[ftlen]
end

function init_furniture(main)
   main.furniture = {}
   main.furniture.bed = {}
   main.furniture.fridge = {}
   main.furniture.stove = {}
   main.furniture.wc = {}
   main.furniture.shower = {}
   main.furniture.radio = {}

   -- bed time
   local cur = add_furniture(main, "furniture", "bed",
		       Rect.new(680, 505, 48, 71), "Interior.png",
		       50, "erkk bed")

   cur = add_furniture(main, "furniture", "bed",
		       Rect.new(416, 102, 64, 90),
		       "open_tileset.png",
		       20, "sleepy Pi")
   cur.stat = {}
   cur.stat.energy = 50
   cur = add_furniture(main, "furniture", "bed",
		       Rect.new(896, 0, 64, 90), "Interior.png",
		       50, "King's bed")
   cur.stat = {}
   cur.stat.energy = 100
   add_furniture(main, "furniture", "stove",
		 Rect.new(32, 114, 31, 44), "open_tileset.png",
		 15, "erkk stove")
   add_furniture(main, "furniture", "stove",
		 Rect.new(32, 114, 31, 44), "open_tileset.png",
		 15, "hot steve")
   add_furniture(main, "furniture", "fridge",
		 Rect.new(0, 97, 32, 61), "open_tileset.png",
		 15, "erkk fridge")
   add_furniture(main, "furniture", "fridge",
		 Rect.new(0, 97, 32, 61), "open_tileset.png",
		 15, "cold maiden")
   add_furniture(main, "furniture", "wc",
		 Rect.new(3, 293, 27, 40), "open_tileset.png",
		 15, "erkk wc")
   add_furniture(main, "furniture", "wc",
		 Rect.new(899, 132, 26, 42), "Interior2.png",
		 15, "free duke")
   add_furniture(main, "furniture", "shower",
		 Rect.new(708, 352, 22, 16), "Interior.png",
		 15, "erkk shower")
   add_furniture(main, "furniture", "shower",
		 Rect.new(64, 256, 32, 90), "open_tileset.png",
		 15, "clean clea")
   add_furniture(main, "furniture", "radio",
		 Rect.new(192, 108, 32, 52), "open_tileset.png",
		 15, "blowing rad")
end

function push_resource(resources, path, rect)
   local l = resources:len()

   resources[l] = {}
   resources[l].img = path
   resources[l]["img-src-rect"] = rect:cent()
   return l
end

function init_new_cloth(main, path, price, name)
   local l = main.clothes:len()
   local isBuy = 0

   if price == 0 then
      isBuy = 1
   end
   main.clothes[l] = {}
   main.clothes[l].is_buy = isBuy
   main.clothes[l].price = price
   main.clothes[l].name = name
   main.clothes[l].resources = {}

   local rs = main.clothes[l].resources
   basic_front_pos = push_resource(rs, path, Rect.new(16, 652, 32, 51))
   basic_back_pos = push_resource(rs, path, Rect.new(16, 525, 32, 51))
   basic_left_pos = push_resource(rs, path, Rect.new(16, 588, 32, 51))
   basic_right_pos = push_resource(rs, path, Rect.new(16, 715, 32, 51))
   step1_front_pos = push_resource(rs, path, Rect.new(144, 652, 32, 51))
   step1_back_pos = push_resource(rs, path, Rect.new(144, 525, 32, 51))
   step1_left_pos = push_resource(rs, path, Rect.new(144, 588, 32, 51))
   step1_right_pos = push_resource(rs, path, Rect.new(144, 715, 32, 51))
   step2_front_pos = push_resource(rs, path, Rect.new(208, 652, 32, 51))
   step2_back_pos = push_resource(rs, path, Rect.new(208, 525, 32, 51))
   step2_left_pos = push_resource(rs, path, Rect.new(208, 588, 32, 51))
   step2_right_pos = push_resource(rs, path, Rect.new(208, 715, 32, 51))
   step3_front_pos = push_resource(rs, path, Rect.new(399, 652, 32, 51))
   step3_back_pos = push_resource(rs, path, Rect.new(399, 525, 32, 51))
   step3_left_pos = push_resource(rs, path, Rect.new(399, 588, 32, 51))
   step3_right_pos = push_resource(rs, path, Rect.new(399, 715, 32, 51))
   return l
end

function init_pj(main, mainCanvas, saved_data)
   main.clothes = {}

   init_new_cloth(main, "Female_basic.png", 0)
   if saved_data.has_pyjama then
      init_new_cloth(main, "Female_pyjama.png", 0)
   else
      init_new_cloth(main, "Female_pyjama.png", 10, "pyjama")
   end
   init_new_cloth(main, "Female_naked.png", 0)
   if saved_data.has_dress then
      init_new_cloth(main, "Female_dress.png", 0)
   else
      init_new_cloth(main, "Female_dress.png", 40, "dress")
   end
   mainCanvas.resources = main.clothes[0].resources
end

function init_room(ent, mainCanvas)
    local i = 0
    while i < 600 do
    mainCanvas:new_img(i, -20, "Greece.png", Rect.new(325, 192, 59, 64))
    i = i + 59
    end
    i = 0
    while i < 350 do
    mainCanvas:new_img(0, i, "open_tileset.png", Rect.new(28, 34, 5, 15))
    mainCanvas:new_img(635, i, "open_tileset.png", Rect.new(28, 34, 5, 15))
    i = i + 15
    end
    i = 0
    while i < 600 do
    mainCanvas:new_img(i, 320, "Greece.png", Rect.new(325, 192, 59, 64))
    i = i + 59
    end
    mainCanvas:new_img(350, 0, "Interior.png", Rect.new(364, 298, 72, 70))
    mainCanvas:new_img(100, 20, "Interior.png", Rect.new(742, 800, 26, 90))
    mainCanvas:new_img(100, 80, "Interior.png", Rect.new(742, 800, 26, 90))
    mainCanvas:new_img(100, 140, "Interior.png", Rect.new(742, 800, 26, 90))
    mainCanvas:new_img(100, 200, "Interior.png", Rect.new(742, 800, 26, 90))
    mainCanvas:new_img(100, 0, "Interior.png", Rect.new(996, 95, 28, 27))
    mainCanvas:new_img(480, 100, "Interior.png", Rect.new(616, 592, 48, 80))
    mainCanvas:new_img(480, 180, "Interior.png", Rect.new(616, 592, 48, 80))
    mainCanvas:new_img(300, 150, "Interior.png", Rect.new(649, 752, 80, 112))
    mainCanvas:new_img(300, 320, "open_tileset.png", Rect.new(161, 288, 31, 40))
    mainCanvas:new_img(45, 4, "open_tileset.png", Rect.new(161, 288, 31, 40))
    mainCanvas:new_img(200, 20, "open_tileset.png", Rect.new(322, 387, 29, 29))
    
end

function setMenuAction(mainMenu, text, action)
   local idx = mainMenu.entries[0].entries:len()

   mainMenu.entries[0].entries[idx] = {}
   mainMenu.entries[0].entries[idx].action = action
   mainMenu.entries[0].entries[idx].text = text
end

function cleanMenuAction(mainMenu)
   mainMenu.entries[0].entries = {}
end

function pushBar(statueBar, guy, name)

   local rect = Entity.new_array()
   local bypos = 4 + 20 * statueBar.ent.nbBar

   statueBar:new_text(1, bypos, Entity.new_string(name))
   rect[0] = Pos.new(102, 12).ent;
   rect[1] = "rgba: 0 0 0 255";
   statueBar:new_rect(69, bypos + 1, rect)
   rect = Entity.new_array()
   rect[0] = Pos.new(guy[name]:to_int(), 10).ent;
   rect[1] = "rgba: 255 255 255 255";
   local goodBar = statueBar:new_rect(70, bypos + 2, rect)
   guy.bars[name] = goodBar:cent()
   statueBar.ent.nbBar = statueBar.ent.nbBar + 1
end

function statAdd(guy, name, val)
   local statVal = guy[name]:to_int()

   statVal = statVal + val
   if (statVal > 100) then
      statVal = 100
   elseif statVal < 0 then
      statVal = 0
   end
   guy[name] = statVal
   CanvasObj.wrapp(guy.bars[name]):force_size(Pos.new(statVal, 10))
end

function swapToFight(entity)
   local mainMenu = Entity.wrapp(ywCntWidgetFather(entity))
   local main = ywCntWidgetFather(mainMenu:cent())
   local fScreen = Entity.wrapp(main).fightScreen
   local widSize = Entity.wrapp(main).mainScreen["wid-pix"]
   local badGuy = Entity.new_array()

   -- bad guy creationg
   badGuy.life = 100
   badGuy.name = "The Work"
   badGuy.attack = Entity.new_func("attackOfTheWork")

   -- init combat
   ySoundPlayLoop(Entity.wrapp(main).soundrequiem:to_int())
   Entity.wrapp(main).currentmusic = Entity.wrapp(main).soundrequiem:to_int()
   ywReplaceEntry(main, 0, fScreen:cent())
   cleanMenuAction(mainMenu)
   setMenuAction(mainMenu, "work", "phq.attack")
   setMenuAction(mainMenu, "run away", "phq.house_time")
   phqFSAddGuy(main, Canvas.wrapp(fScreen), widSize, badGuy)

   Entity.wrapp(main).guy.movable = 0
   return YEVE_ACTION
end

function update_money(main)
   local statueBar = Canvas.wrapp(main.menuCnt.entries[2])
   local bypos = 4 + 20 * statueBar.ent.nbBar

   statueBar:pop_back()
   statueBar:new_text(69, bypos,
		      Entity.new_string(main.guy.money:to_int()))
end

function remove_phq(entity)
   entity = Entity.wrapp(entity)
   entity.mainScreen = nil
   entity.fightScreen = nil
   entity.invScreen = nil
   entity.menuCnt = nil
end

function create_phq(entity)
   local container = Container.init_entity(entity, "horizontal")
   local ent = container.ent

   -- create good guy
   if ent.saved_data then
      ent.guy = ent.saved_data.guy
      ent.cur_objs = ent.saved_data.cur_objs
   else
      ent.guy = {}
      ent.guy.bars = {}
      ent.guy.money = 27
      ent.guy.hygien = 100
      ent.guy.fun = 10
      ent.guy.energy = 100
      ent.guy.hunger = 100
      ent.guy.bladder = 100
      ent.cur_objs = {}
      ent.cur_objs.bed = 0
      ent.cur_objs.fridge = 0
      ent.cur_objs.stove = 0
      ent.cur_objs.wc = 0
      ent.cur_objs.shower = 0
      ent.cur_objs.radio = 0
   end
   ent.guy.attack = Entity.new_func("attackTheWork")

   -- create widget
   ent["turn-length"] = 30000
   ent.destroy = Entity.new_func("remove_phq")
   ent.step = 0
   ent.move = {}
   ent.move.up_down = 0
   ent.move.left_right = 0
   Entity.new_func("phq_action", ent, "action")

   ent.background = "rgba: 255 255 127 255"
   local mainCanvas = Canvas.new_entity(entity, "mainScreen")
   local fightCanvas = Canvas.new_entity(entity, "fightScreen")
   local invCanvas = Canvas.new_entity(entity, "invScreen")
   ent.entries = {}
   ent.entries[0] = mainCanvas.ent  -- game screen
   ent.entries[0].size = 70
   ent.current = 1
   -- bottom box
   local menu_cnt = Container.new_entity("vertical", entity, "menuCnt")
   ent.entries[1] = menu_cnt.ent
   menu_cnt.ent.background = "rgba: 127 127 255 255"
   menu_cnt.ent.entries[0] = Menu:new_entity().ent
   menu_cnt.ent.entries[0].background = "rgba: 127 255 255 255"
   menu_cnt.ent.entries[0].size = 40
   menu_cnt.ent.entries[1] = Canvas:new_entity().ent
   menu_cnt.ent.entries[1].background = "rgba: 255 255 255 255"
   menu_cnt.ent.entries[1].size = 20
   menu_cnt.ent.entries[2] = Canvas:new_entity().ent
   menu_cnt.ent.entries[2].size = 40
   menu_cnt.ent.entries[2].background = "rgba: 127 127 255 255"

   local statueBar = Canvas.wrapp(menu_cnt.ent.entries[2])

   statueBar.ent.nbBar = 0
   pushBar(statueBar, ent.guy, "hygien")
   pushBar(statueBar, ent.guy, "fun")
   pushBar(statueBar, ent.guy, "energy")
   pushBar(statueBar, ent.guy, "hunger")
   pushBar(statueBar, ent.guy, "bladder")

   -- music
   ent.soundhouse = ySoundLoad("./house_music.mp3") 
   ent.soundpft = ySoundLoad("./pft.mp3")
   ent.soundcallgirl = ySoundLoad("./callgirl.mp3")
   ent.soundrequiem = ySoundLoad("./rekuiemu.mp3")
   ent.currentmusic = ent.soundcallgirl

   -- money
   local bypos = 4 + 20 * statueBar.ent.nbBar
   statueBar:new_text(1, bypos, Entity.new_string("money"))
   ent.money_pos = bypos
   statueBar:new_text(69, bypos, Entity.new_string(ent.guy.money:to_int()))

   local ret = container:new_wid()
   local mn = menu_cnt.ent.entries[0]
   init_furniture(ent)
   if ent.saved_data == nil then
      ent.saved_data = {}
   end
   init_pj(ent, mainCanvas.ent, ent.saved_data)
   ent.guy.canvas = mainCanvas:new_obj(150, 150, basic_front_pos):cent()
   init_room(ent, mainCanvas)
   ent.saved_data = nil
   swapToHouse(mn:cent())
   return ret
end
