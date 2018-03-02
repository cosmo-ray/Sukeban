local objWSize = 110
local objHSize = 140

function display_furniture(furn, invScreen, t, xThreshold, yThreshold)
   local pos = 0 + xThreshold

   for i = 1, furn[t]:len() do
      if furn[t][i] then
	 invScreen.ent.posInfo[invScreen.ent.nbFurniture:to_int()] = {}
	 local posInfo = invScreen.ent.posInfo[invScreen.ent.nbFurniture:to_int()]
	 invScreen.ent.nbFurniture = invScreen.ent.nbFurniture + 1
	 posInfo.furn = furn[t][i]
	 posInfo.pos = Pos.new(pos, yThreshold).ent
	 posInfo.type = t
	 posInfo.realIdx = i

	 invScreen:new_text(1 + pos, 0 + yThreshold,
			    Entity.new_string(furn[t][i].name:to_string()))
	 invScreen:new_img(pos, 20 + yThreshold, furn[t][i].path:to_string(),
			   furn[t][i].rect)
	 invScreen:new_text(1 + pos, 120 + yThreshold,
			    Entity.new_string(furn[t][i].price:to_string() .. "$"))
	 pos = pos + objWSize
      end
   end
   return furn[t]:len() - 1
end

function shoop_cursor_move(main, invScreen, move)
   invScreen.current_pos = invScreen.current_pos + move

   if invScreen.current_pos < 0 then
      invScreen.current_pos = invScreen.nbFurniture + -1
   elseif invScreen.current_pos >= invScreen.nbFurniture then
      invScreen.current_pos = 0
   end
   local realPos = Pos.wrapp(invScreen.posInfo[invScreen.current_pos:to_int()].pos)
   CanvasObj.wrapp(invScreen.rect):set_pos(realPos:x(), realPos:y())
end

function init_clothes_furnitur(main, invScreen, shoud_be_buy)
   invScreen.nbFurniture = 0
   invScreen.posInfo = {}
   invScreen.resources = {}
   invScreen = Canvas.wrapp(invScreen)

   for i = 0, invScreen.ent.objs:len() do
      invScreen:pop_back()
   end

   local j = 0
   for i = 0, main.clothes:len() do
      if main.clothes[i] and main.clothes[i].is_buy:to_int() == shoud_be_buy then
	 invScreen.ent.posInfo[j] = {}
	 local posInfo = invScreen.ent.posInfo[j]
	 posInfo.furn = main.clothes[i]
	 posInfo.pos = Pos.new(j * objWSize, 0).ent
	 posInfo.realIdx = i
	 posInfo.name = main.clothes[i].name
	 invScreen.ent.resources[j] = main.clothes[i].resources[0]
	 invScreen:new_obj(j * objWSize, 20, j)
	 if shoud_be_buy == 0 then
	    invScreen:new_text(j * objWSize, 0,
			       Entity.new_string(main.clothes[i].price:to_string() .. "$"))
	 end

	 j = j + 1
      end
   end
   invScreen.ent.nbFurniture = j
   local rect = Entity.new_array()
   rect[0] = Pos.new(objWSize, objHSize).ent;
   rect[1] = "rgba: 127 0 0 100";
   invScreen.ent.rect = invScreen:new_rect(0, 0, rect):cent()
   invScreen.ent.current_pos = 0

end

function init_shop_furnitur(main, invScreen, furn)
   invScreen.nbFurniture = 0
   invScreen.posInfo = {}

   invScreen = Canvas.wrapp(invScreen)

   for i = 0, invScreen.ent.objs:len() do
      invScreen:pop_back()
   end

   local nb = display_furniture(furn, invScreen, "bed", 0, 0)
   nb = display_furniture(furn, invScreen, "fridge", nb * objWSize, 0) + nb
   display_furniture(furn, invScreen, "stove", nb * objWSize, 0)
   nb = display_furniture(furn, invScreen, "wc", 0, objHSize)
   nb = display_furniture(furn, invScreen, "shower", nb * objWSize, objHSize) + nb
   display_furniture(furn, invScreen, "radio", nb * objWSize, objHSize)
   local rect = Entity.new_array()
   rect[0] = Pos.new(objWSize, objHSize).ent;
   rect[1] = "rgba: 127 0 0 100";
   invScreen.ent.rect = invScreen:new_rect(invScreen.ent.posInfo[0].pos.x:to_int(),
					   invScreen.ent.posInfo[0].pos.x:to_int(),
					   rect):cent()
   invScreen.ent.current_pos = 0
end

function shop_buy(entity)
   local mainMenu = Entity.wrapp(ywCntWidgetFather(entity))
   local main = Entity.wrapp(ywCntWidgetFather(mainMenu:cent()))
   local invScreen = main.invScreen
   local newObj = invScreen.posInfo[invScreen.current_pos:to_int()]
   local mainCanvas = Canvas.wrapp(main.mainScreen)
   local t = newObj.type:to_string()
   local posx = main[t].pos.x
   local posy = main[t].pos.y

   if (main.guy.money - newObj.furn.price < 0) then
      display_text(main, "you're too poor for that", 20, 300)
      return
   end
   mainCanvas:remove(main[t])
   main[t] = mainCanvas:new_img(posx:to_int(), posy:to_int(),
				   newObj.furn.path:to_string(),
				   newObj.furn.rect):cent()
   main[t].stat = newObj.furn.stat
   --print("realIdx", newObj.realIdx)
   main.cur_objs[t] = newObj.realIdx
   main.guy.money = main.guy.money - newObj.furn.price
   update_money(main)
end

function cloth_buy(entity)
   local mainMenu = Entity.wrapp(ywCntWidgetFather(entity))
   local main = Entity.wrapp(ywCntWidgetFather(mainMenu:cent()))
   local invScreen = main.invScreen
   local newObj = invScreen.posInfo[invScreen.current_pos:to_int()]
   if (main.guy.money - newObj.furn.price < 0) then
      display_text(main, "you're too poor for that", 20, 300)
      return
   end
   if newObj.furn.is_buy:to_int() == 1 then
      display_text(main, "I alerady have that", 20, 300)
      return
   end
   display_text(main, "congratulation, a new cloth is in you invenory", 20, 300)
   newObj.furn.is_buy = 1
   main.guy.money = main.guy.money - newObj.furn.price
   main["has_" .. newObj.furn.name:to_string()] = 1
   update_money(main)
end

function ware_cloth(entity)
   local mainMenu = Entity.wrapp(ywCntWidgetFather(entity))
   local main = Entity.wrapp(ywCntWidgetFather(mainMenu:cent()))
   local invScreen = main.invScreen
   local obj = invScreen.posInfo[invScreen.current_pos:to_int()]

   --print("change to", obj.realIdx:to_int(),
	-- main.clothes[obj.realIdx:to_int()].resources,
	 --main.mainScreen.resources)
   main.mainScreen.resources = main.clothes[obj.realIdx:to_int()].resources
   ywCanvasObjClearCache(main.guy.canvas:cent())
end

function swapToClothShop(entity)
   local mainMenu = Entity.wrapp(ywCntWidgetFather(entity))
   local main = ywCntWidgetFather(mainMenu:cent())
   local invScreen = Entity.wrapp(main).invScreen

   ywReplaceEntry(main, 0, invScreen:cent())
   cleanMenuAction(mainMenu)
   setMenuAction(mainMenu, "buy",
		 Entity.new_func("cloth_buy"))
   setMenuAction(mainMenu, "go to leakea",
		 Entity.new_func("swapToShop"))
   setMenuAction(mainMenu, "go home", "phq.house_time")
   main = Entity.wrapp(main)
   main.guy.movable = 0
   init_clothes_furnitur(main, invScreen, 0)
end

function swapToChangeCloth(entity)
   local mainMenu = Entity.wrapp(ywCntWidgetFather(entity))
   local main = Entity.wrapp(ywCntWidgetFather(mainMenu:cent()))
   local invScreen = main.invScreen

   ywReplaceEntry(main:cent(), 0, invScreen:cent())
   cleanMenuAction(mainMenu)
   setMenuAction(mainMenu, "ware",
		 Entity.new_func("ware_cloth"))
   setMenuAction(mainMenu, "close", "phq.house_time")
   main.guy.movable = 0
   init_clothes_furnitur(main, invScreen, 1)
end

function swapToShop(entity)
   local mainMenu = Entity.wrapp(ywCntWidgetFather(entity))
   local main = ywCntWidgetFather(mainMenu:cent())
   local invScreen = Entity.wrapp(main).invScreen

   -- init combat
   ywReplaceEntry(main, 0, invScreen:cent())
   cleanMenuAction(mainMenu)
   setMenuAction(mainMenu, "buy", Entity.new_func("shop_buy"))
   setMenuAction(mainMenu, "go to cloth shop",
		 Entity.new_func("swapToClothShop"))
   setMenuAction(mainMenu, "go home", "phq.house_time")
   main = Entity.wrapp(main)
   init_shop_furnitur(main, invScreen, main.furniture)
   Entity.wrapp(main).guy.movable = 0
   return YEVE_ACTION
end
