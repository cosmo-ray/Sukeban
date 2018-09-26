local modPath = Entity.wrapp(ygGet("phq.$path")):to_string()
local stations = File.jsonToEnt(modPath .. "/metro.json")
local phq = Entity.wrapp(ygGet("phq"))
local arrow_path = Entity.wrapp(ygGet("DialogueBox.$path")):to_string() .. "/arrow_sheet.png"

function unpushMetroMenu(metro)
   print("unpush !")
   ywCntPopLastEntry(ywCntWidgetFather(metro))
   return YEVE_ACTION
end

function metroAction(metroMap, eve)
   eve = Event.wrapp(eve)

   while eve:is_end() == false do
      if eve:type() == YKEY_DOWN then
	 if eve:key() == Y_ESC_KEY or
	 eve:key() == Y_M_KEY then
	    return unpushMetroMenu(metroMap)
	 end
      end
      eve = eve:next()
   end
end

function pushMetroMenu(main)
   local station_info = phq.env.station
   local line = stations[station_info[0]:to_int()]
   local station = line[station_info[1]:to_int()]
   local can = Canvas.new_entity()

   can:new_img(0, 0, modPath .. "/metro.png")
   can.ent.rect = can:new_rect(station[0] - 10, station[1] - 10,
			       "rgba: 0 0 0 124",
			       Size.new(20, 20).ent)
   can.ent.arrow = can:new_img(station[0] - 35,
			       station[1] - 10, arrow_path,
			       Rect.new(0, 0, 25, 20).ent)

   can:new_rect(20, 550, "rgba: 0 0 0 124", Size.new(20, 20).ent)
   can:new_text(50, 550, Entity.new_string(": current position"))
   can:new_img(20, 520, arrow_path, Rect.new(0, 0, 25, 20).ent)
   can:new_text(50, 520, Entity.new_string(": destination"))
   can:new_text(150, 30, Entity.new_string(
		   "Welcom to [City Name Not Yet Decided] Metro Plan"))

   can.ent.action = Entity.new_func("metroAction")
   can.ent.line = line
   can.ent.station_info = station_info
   can.ent.station = station
   ywPushNewWidget(main, can.ent)
end

