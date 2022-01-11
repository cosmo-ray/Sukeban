--
--Copyright (C) 2022 Matthias Gatto
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Lesser General Public License as published by
--the Free Software Foundation, either version 3 of the License, or
--(at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU General Public License for more details.
--
--You should have received a copy of the GNU Lesser General Public License
--along with this program.  If not, see <http://www.gnu.org/licenses/>.
--

local modPath = Entity.wrapp(ygGet("phq.$path")):to_string()
local metro_file = File.jsonToEnt(modPath .. "/metro.json")
local phq = Entity.wrapp(ygGet("phq"))
local arrow_path = Entity.wrapp(ygGet("DialogueBox.$path")):to_string() .. "/arrow_sheet.png"
local line_actual0 = "currently on line: "
local ST_NAME_IDX = 2
usable_metro = false

local cur_action = nil

local function sl_quit()
   ywCntPopLastEntry(main_widget)
end

local function show_sl()
   local sl_wid = Entity.new_array()

   sl_wid["<type>"] = "capp"
   sl_wid.files = {}
   sl_wid.files[0] = "./modules/sl/sl.c"
   sl_wid.args = {}
   sl_wid.args[0] = "-G"
   sl_wid.args[1] = "-w"
   sl_wid.background = "rgba: 255 255 255 127"
   sl_wid.quit = Entity.new_func(sl_quit)
   ywPushNewWidget(main_widget, sl_wid)
   ywCntConstructChilds(main_widget)
   ywidActions(sl_wid, sl_wid, nil);
end

local function sl_action(wid)
   local action = cur_action
   cur_action = nil
   print("SL ACTION", wid, action)
   show_sl()
   return ywidAction(action, wid, nil)
end

local function printable_st_name(station)
   local st_name = yeGet(station, ST_NAME_IDX)

   if yeType(st_name) == YSTRING then
      return "station: " .. yeGetString(st_name)
   end
   return "some random station from this random town"
end

local function gotoStation(metroMap, station_idx, line_idx)
   if line_idx then
      metroMap.station_info[0] = line_idx
      print(metroMap.line)
      metroMap.line = metro_file.lines[line_idx]
      print(metroMap.line, line_idx, metro_file.lines[1])
   else
      line_idx = metroMap.station_info[0]:to_int()
   end
   metroMap.station_info[1] = station_idx
   local station = metroMap.line[station_idx]
   metroMap.station = station
   ywCanvasObjSetPos(metroMap.arrow, station[0] - 35,
		     station[1] - 10)
   ywCanvasStringSet(metroMap.line_txt_info,
		     Entity.new_string(line_actual0 .. math.floor(line_idx)))
   ywCanvasStringSet(metroMap.st_txt_info,
		     Entity.new_string(printable_st_name(metroMap.station)))
   yeCopy(metroMap.station_info, phq.env.station)
   return YEVE_ACTION
end

function setCurStation(main, useless, line, station)
   phq.env.station[0] = line
   phq.env.station[1] = station
end

local function do_encounter(metroMap, enc, next_enc, action)
   local encounter_wid = Entity.new_array()
   local dial = nil
   local enemies = enc.enemies
   encounter_wid[0] = {}
   dial = encounter_wid[0]

   -- see if we avoid the attack
   if yuiRand() % 100 > yeGetIntAt(enc, "%") then
      if next_enc and next_enc ~= true then
   	 return do_encounter(metroMap, next_enc, nil, action)
      end
      show_sl()
      return ywidAction(action, metroMap, eve)
   end
   if (next_enc) then
      dial.text = "your party are under attack, you must defend yourself"
   else
      if phq.pj.archetype == GEEK_ARCHETYPE then
	 dial.text = 'you hear peoples singing "lalah" "lalah"\n'..
	    "and on the begining of your trip\n" ..
	    "you have an encounter in metro\n"
      else
   	 dial.text = "you go to the metro, and BOUM\nENEMIES"
      end
   end

   dial.answer = {}
   if phq.pj.archetype == BRUTE_ARCHETYPE then
      dial.answer.text = "M.U.S.C.L.E Girl, GO FIGHT !"
   elseif phq.pj.archetype == WORMS_COINOISSEUR_ARCHETYPE then
      dial.answer.text = "aye I'm dead"
   else
      dial.answer.text = "FIGHT !"
   end
   --dial.answer.action = "Dialogue:gotoNext"
   dial.answer.action = {}
   local a = dial.answer.action
   local nb_enemies = yuiRand() % yeGetIntAt(enemies, 2) + 1
   if nb_enemies < yeGetIntAt(enemies, 1) then
      nb_enemies = yeGetIntAt(enemies, 1)
   end
   a[0] = "phq.StartFight"
   a[1] = {}
   local i = 0
   while i < nb_enemies do
      a[1][i] = yeGet(enemies, 0)
      i = i + 1
   end
   a[2] = "CombatDialogueNext"
   -- "action": [ "phq.StartFight", "rat", "CombatDialogueNext"]
   encounter_wid[1] = {}
   dial = encounter_wid[1]
   dial.text = "WINNER FOREVER ! (you definitively got a strike team)"
   dial.answer = {}
   dial.answer.text = "Stand up for the victory !"
   if next_enc then
      show_sl()
      dial.answer.action = action
   else
      cur_action = action
      dial.answer.action = Entity.new_func(sl_action)
   end

   backToGame(metroMap)
   --return YEVE_ACTION
   return vnScene(main_widget, nil, encounter_wid)
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
	 elseif eve:key() == Y_ENTER_KEY and usable_metro then
	    local station_name = metroMap.station[ST_NAME_IDX]
	    if station_name then
	       local action = metro_file.actions[station_name:to_string()]
	       local condition = metro_file.conditions[station_name:to_string()]
	       local encount_dest = metro_file.encounter[station_name:to_string()]
	       local o_station_name = yeGetString(metroMap.o_station[ST_NAME_IDX])
	       local encount_src = metro_file.encounter[o_station_name]

	       print("info: ", station_name, metroMap.station,
		     metroMap.station_info,
		     metroMap.o_station[ST_NAME_IDX])
	       --[station_info[1]:to_int()]
	       if station_name:to_string() == "Nontoise" or
	       station_name:to_string() == "Nontoise Gate" then
		  goto goto_station
	       elseif (condition == nil or  yeCheckCondition(condition)) and
	       use_time_point() == Y_TRUE then
		  goto goto_station
	       else
		  local str = Entity.new_string("NOT ENOUTH TIME POINT")
		  print("NOT ENOUTH TIME POINT")
		  ywCanvasStringSet(metroMap.info_txt, str)
	       end
	       :: goto_station ::
	       usable_metro = false
	       if encount_src then
		  return do_encounter(metroMap, encount_src,
				      encount_dest, action)
	       end

	       if encount_dest then
		  return do_encounter(metroMap, encount_dest, true, action)
	       end

	       show_sl()
	       return ywidAction(action, metroMap, eve)
	    end
	 elseif eve:key() == Y_ESC_KEY or
	 eve:key() == Y_M_KEY then
	    usable_metro = false
	    return gmGetBackFocus(metroMap)
	 end
      end
      eve = eve:next()
   end
   return YEVE_ACTION
end

function pushMetroMenu(main)
   local lines = metro_file.lines
   local intersections = metro_file.intersections
   local station_info = Entity.new_copy(phq.env.station)
   local l_idx = station_info[0]:to_int()
   local line = lines[l_idx]
   local station = line[station_info[1]:to_int()]
   local can = Canvas.new_entity()

   can:new_img(0, 0, modPath .. "/metro.png")
   can.ent.arrow = can:new_img(station[0] - 35,
			       station[1] - 10, arrow_path,
			       Rect.new(0, 0, 25, 20).ent).ent
   local info_str = ""

   if usable_metro == true then
      can.ent.rect = can:new_rect(station[0] - 10, station[1] - 10,
				  "rgba: 0 0 0 124",
				  Size.new(20, 20).ent).ent
      can:new_rect(20, 550, "rgba: 0 0 0 124", Size.new(20, 20).ent)
      can:new_text(50, 550, ": current position")
      can:new_text(50, 520, ": destination")
   else
      info_str = "NOT CURRENTLY IN A METRO"
      can:new_text(50, 520, ": pointed station")
   end
   can.ent.info_txt = can:new_text(250, 100, info_str).ent
   can:new_text(150, 30, "Welcom to " .. phq.env.city:to_string() .. " Metro Plan")

   can.ent.line_txt_info = can:new_text(250, 60,
					line_actual0 .. math.floor(l_idx)).ent
   can.ent.st_txt_info = can:new_text(250, 80, printable_st_name(station)).ent

   can:new_img(20, 520, arrow_path, Rect.new(0, 0, 25, 20).ent)

   can:new_text(500, 500, "left/right: change station\n\nup/down: change line")
   can.ent.action = Entity.new_func("metroAction")
   can.ent.line = line
   can.ent.station_info = station_info
   can.ent.station = station
   can.ent.o_station = Entity.new_copy(station)
   ywPushNewWidget(main, can.ent)
   return can.ent
end

