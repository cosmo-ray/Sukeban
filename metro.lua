local modPath = Entity.wrapp(ygGet("phq.$path")):to_string()
local metro_file = File.jsonToEnt(modPath .. "/metro.json")
local phq = Entity.wrapp(ygGet("phq"))
local arrow_path = Entity.wrapp(ygGet("DialogueBox.$path")):to_string() .. "/arrow_sheet.png"
local line_actual0 = "currently on line: "

local function gotoStation(metroMap, station_idx, line_idx)
   if line_idx then
      metroMap.station_info[0] = line_idx
      print(metroMap.line)
      metroMap.line = metro_file.lines[line_idx]
      print(metroMap.line, line_idx, metro_file.lines[1])
   else
      line_idx = metroMap.station_info[0]:to_int()
   end
   ywCanvasStringSet(metroMap.line_txt_info,
		     Entity.new_string(line_actual0 .. math.floor(line_idx)))
   metroMap.station_info[1] = station_idx
   local station = metroMap.line[station_idx]
   metroMap.station = station
   ywCanvasObjSetPos(metroMap.arrow, station[0] - 35,
		     station[1] - 10)
   yeCopy(metroMap.station_info, phq.env.station)
   return YEVE_ACTION
end

function metroAction(metroMap, eve)
   metroMap = Entity.wrapp(metroMap)
   eve = Event.wrapp(eve)

   while eve:is_end() == false do
      if eve:type() == YKEY_DOWN then
	 if eve:is_key_left() then
	    local station_idx = metroMap.station_info[1]:to_int()
	    local line = metroMap.line

	    if station_idx > 0 then
	       station_idx = station_idx - 1
	       return gotoStation(metroMap, station_idx)
	    end
	 elseif eve:is_key_right() then
	    local station_idx = metroMap.station_info[1]:to_int()
	    local line = metroMap.line

	    if station_idx < yeLen(line) - 1 then
	       station_idx = station_idx + 1
	       return gotoStation(metroMap, station_idx)
	    end
	 elseif eve:is_key_up() or eve:is_key_down() then
	    local intersections = metro_file.intersections

	    local i = 0
	    while (i < yeLen(intersections)) do
	       local intersect = intersections[i]
	       local station_info = metroMap.station_info
	       local dest_s_idx = nil
	       local dest_l_idx = nil
	       local match = 0

	       if station_info[0] == intersect[0][0] and
	       station_info[1] == intersect[0][1] then
		  dest_l_idx = intersect[1][0]
		  dest_s_idx = intersect[1][1]
		  match = 1
	       elseif station_info[0] == intersect[1][0] and
	       station_info[1] == intersect[1][1] then
		  dest_l_idx = intersect[0][0]
		  dest_s_idx = intersect[0][1]
		  match = 1
	       end
	       if match == 1 then
		  return gotoStation(metroMap, dest_s_idx:to_int(),
				     dest_l_idx:to_int())
	       end
	       i = i + 1
	    end
	 elseif eve:key() == Y_ENTER_KEY then
	    local station_name = metroMap.station[2]
	    if station_name then
	       local action = metro_file.actions[station_name:to_string()]
	       return ywidAction(action, metroMap, eve)
	    end
	 elseif eve:key() == Y_ESC_KEY or
	 eve:key() == Y_M_KEY then
	    return gmGetBackFocus(metroMap)
	 end
      end
      eve = eve:next()
   end
   return YEVE_NOTHANDLE
end

function pushMetroMenu(main)
   local lines = metro_file.lines
   local intersections = metro_file.intersections
   local station_info = Entity.new_array()
   yeCopy(phq.env.station, station_info)
   local line = lines[station_info[0]:to_int()]
   local station = line[station_info[1]:to_int()]
   local can = Canvas.new_entity()

   print(intersections)
   can:new_img(0, 0, modPath .. "/metro.png")
   can.ent.rect = can:new_rect(station[0] - 10, station[1] - 10,
			       "rgba: 0 0 0 124",
			       Size.new(20, 20).ent).ent
   can.ent.arrow = can:new_img(station[0] - 35,
			       station[1] - 10, arrow_path,
			       Rect.new(0, 0, 25, 20).ent).ent

   can:new_rect(20, 550, "rgba: 0 0 0 124", Size.new(20, 20).ent)
   can:new_text(50, 550, ": current position")
   can:new_img(20, 520, arrow_path, Rect.new(0, 0, 25, 20).ent)
   can:new_text(50, 520, ": destination")
   can:new_text(150, 30, "Welcom to [City Name Not Yet Decided] Metro Plan")
   can.ent.line_txt_info = can:new_text(250, 60, line_actual0).ent

   can:new_text(500, 500, "left/right: change station\n\nup/down: change line")
   can.ent.action = Entity.new_func("metroAction")
   can.ent.line = line
   can.ent.station_info = station_info
   can.ent.station = station
   ywPushNewWidget(main, can.ent)
   return can.ent
end

