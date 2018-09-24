local modPath = Entity.wrapp(ygGet("phq.$path")):to_string()
local stations = File.jsonToEnt(modPath .. "/metro.json")
local phq = Entity.wrapp(ygGet("phq"))

function unpushMetroMenu(metro)
   print("unpush !")
   ywCntPopLastEntry(ywCntWidgetFather(metro))
   return YEVE_ACTION
end

function metroAction(metroMap, eve)
   eve = Event.wrapp(eve)

   while eve:is_end() == false do
      if eve:key() == Y_ESC_KEY then
	 return unpushMetroMenu(metroMap)
      end
      eve = eve:next()
   end
end

function pushMetroMenu(main)
   local station_info = phq.env.station
   local line = stations[station_info[0]:to_int()]
   local station = line[station_info[1]:to_int()]
   print("Metro Time !", station)
   local can = Canvas.new_entity()

   can:new_img(0, 0, modPath .. "/metro.png")
   can.ent.action = Entity.new_func("metroAction")
   can.ent.line = line
   can.ent.station_info = station_info
   can.ent.station = station
   ywPushNewWidget(main, can.ent)
end

