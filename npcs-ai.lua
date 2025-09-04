--
--Copyright (C) 2022-2025 Matthias Gatto
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

local phq = Entity.wrapp(ygGet("phq"))

local function push_to_ai_point_(map, p, name, check)
   if yIsNil(map) then
      return false
   end
   print("? ", map, p, name, check, " ?")
   if phq.env.ai_point == nil then
      phq.env.ai_point = {}
   end
   if phq.env.ai_point[map] == nil then
      phq.env.ai_point[map] = {}
   end

   if check and yIsNNil(phq.env.ai_point[map][p]) then
      return false
   end
   phq.env.ai_point[map][p] = name
   print("sucess")
   return true
end

local function push_to_ai_point(map, p, name)
   return push_to_ai_point_(map, p, name, false)
end

local function push_to_const_ai_point(place, ai_point, who)
   local caip = yeTryCreateArray(phq.env, "const_ai_p")
   local caip_who = yeTryCreateArray(caip, who)
   yeCreateString(place, caip_who)
   yeCreateString(ai_point, caip_who)
   push_to_ai_point(place, ai_point, who)
end

local function remove_const_ai_point(who)
   local caip_info = phq.env.const_ai_p[who]

   phq.env.ai_point[caip_info[0]][caip_info[1]] = nil
   phq.env.const_ai_p[who] = nil
end

function wouaf_ai(_main, _npc, name)
   local t = ygGetString("phq.env.time")

   if is_npc_ally(phq.pj, name) then
      if (t == "night") then
	 leave_team(name)
      end
   end
end

local orga_to_scene = {
   ["Computer club"] = "school_computer_club",
   ["Animu Club"] = "school_animu_club",
   ["Mystical Neet Go-under"] = "hiden_house",
   ["Board Game and Roleplay Club"] = "school_boardgame_club",
   ["Students Protection Group"] = "school_roof_room",
   ["Wheelball School Team"] = "team_sport_clubs",
   ["Music club"] = "music_club"
}

local ai_points = {
   ["school_under"] = {
      { ["p"] = "talk_0" },
      { ["p"] = "talk_1" },
      { ["p"] = "talk_2" },
      { ["p"] = "talk_3" },
   },
   ["school0"] = {
      { ["p"] = "s0_3talk_0" },
      { ["p"] = "s0_3talk_1" },
      { ["p"] = "s0_3talk_2" },
      { ["p"] = "s0_uw" }
   },
   ["street3"] = {
      { ["p"] = "f0_t2_1" },
      { ["p"] = "f0_t2_0" },
      { ["p"] = "r_t2_0" },
      { ["p"] = "r_t2_1" }
   },
   ["class"] = {
      { ["p"] = "p_0" },
      { ["p"] = "p_1" },
      { ["p"] = "p_2" },
      { ["p"] = "p_3" },
      { ["p"] = "p_4" }
   },
   ["club"] = {
      { ["p"] = "p0" },
      { ["p"] = "p1" },
   },
   ["house"] = {
      { ["p"] = "npc_bed" }
   }
}

function increase_relation_2npc(src, dst_name, nb)
   local orelations = Entity.wrapp(yeTryCreateArray(src, "onpc_relation"))
   local orelation = Entity.wrapp(yeTryCreateArray(orelations, dst_name))
   local oaffaction = yeTryCreateInt(0, orelation, "affection")

   yeSetInt(oaffaction, yeGetInt(oaffaction) + nb)
   print("nb: ", nb, yeGetInt(oaffaction) + nb)
   yePrint(src)
end

function student_ai(_main, npc, name)
   local t = ygGetString("phq.env.time")
   local c = ygGetInt("phq.env.chapter")
   local d = ygGetInt("phq.env.day")
   npc = Entity.wrapp(npc)

   if npc._holded and npc._holded > 0 then
      return
   end

   print("student_ai", name, c, d, t)
   -- COULD BE SO MUCH IMPROVE:
   if yuiRand() % 2 == 0 then -- 50% chances in teraction
      local onpc_i = yuiRand() % yeLen(npcs)
      local onpc = npcs[onpc_i]

      print("random interaction: ", npc, "\n======\n", onpc)
      if yIsNil(onpc) or onpc == npc then
	 goto out
      end

      local oname = yeGetStringAt(onpc.name)

      if yIsNil(oname) then
	 oname = yeGetKeyAt(npcs, onpc_i)
      end

      if yuiRand() % 2 == 0 then -- good one
	 print(name, "have a good interaction with", oname)
	 increase_relation_2npc(npc, oname, yuiRand() % 5 + 1)
	 increase_relation_2npc(onpc, name, yuiRand() % 5 + 1)
      else -- bad one
	 increase_relation_2npc(src, oname, -(yuiRand() % 5 + 1))
	 increase_relation_2npc(oname, name, -(yuiRand() % 5 + 1))
	 print(name, "have a bad interaction with", oname)
      end
      :: out ::
   end

   if c ~= 1 then
      return
   end
   local cur_pos = name .. " House"

   if t == "morning" and d < 6 then
      local r = yuiRand() % 5
      if r == 0 then
	 cur_pos = "school0"
      elseif r == 1 then
	 cur_pos = "street3"
      elseif r == 2 then
	 cur_pos = "school_under"
      elseif r == 3 then
	 cur_pos = "club"
      else
	 cur_pos = "class"
	 print("IN CLASS: ", npc.class_id)
	 -- find other place to be
	 -- also compute which class if still in class
      end
      print("School Time")
   elseif t == "night" then
      print("morning")
   elseif t == "day" then
      if yIsNNil(yeGet(npc, "house")) then
	 cur_pos = "house"
      end
      print("night")
   else
      print("fin de semaine !")
   end

   local csap = ai_points[cur_pos]
   if csap ~= nil then
      local idx = 1
      if cur_pos == "house" then
	 cur_pos = yeGetStringAt(npc, "house")
      elseif cur_pos == "club" then
	 local orga = yeGetString(yeGetRandomElem(npc.organisations));

	 cur_pos = orga_to_scene[orga]
	 print("target orga:", orga, cur_pos, csap);
      elseif cur_pos == "class" then
	 local class_id = yeGetIntAt(npc, "class_id")
	 if class_id > 5 then
	    class_id = class_id + 4
	 end
	 cur_pos = "school_class_0" .. math.floor(class_id)
	 print("new cur pos: ", cur_pos)
      end
      npc._cur_pos = cur_pos
      :: again ::
      if idx <= #csap
	 and push_to_ai_point_(cur_pos,
			       csap[idx].p,
			       name, true) == false then
	    idx = idx + 1
	    goto again
      end
      npc = Entity.wrapp(npc)
      npc.out_time = next_time()
   end
   if yeGetIntAt(npc, "is_random_student") > 0 then
      Entity.wrapp(npc).dialogue = Entity.new_string("neutral-student")
   end
   Entity.wrapp(npc).have_talk = 0

   --print("ai of ", name, ":", Entity.wrapp(npc))
   --print("time: ", t, " chapter: ", c)
end

function bob_ai(main, npc, name)
   main = Entity.wrapp(main)
   npc = Entity.wrapp(npc)

   if npc._holded and npc._holded > 0 then
      return
   end

   local c_place = "bob_house"
   local p = yuiRand() % 100

   if (p < 50) then
      c_place = "street3"
   end
   npc._place = c_place
   return student_ai(main, npc, name)
end

function mom_ai(main, npc, name)
   npc = Entity.wrapp(npc)
   npc._place = nil
   if phq.env.chapter > 1 and yeGetString(phq.env.time) == "day" then
      npc._place = "gambling_hall"
   end
end


local runner_lpos = nil
local runner0_pos = 0
local runner0_tbl = nil

function runner_0_mk_tbl(_npc, point_prefix, nb_pos, start_p)
   local pos

   if runner0_pos < nb_pos - 2 then
      pos = main_widget.misc[point_prefix .. runner0_pos].rect
   else
      pos = main_widget.ai_point[start_p].rect
      ywPosAddXY(pos, 0, -50);
   end
   ywCanvasDoPathfinding(main_widget.mainScreen, runner_lpos, pos,
			 Pos.new(PIX_PER_FRAME * 1.8, PIX_PER_FRAME * 1.8).ent,
			 runner0_tbl)

   runner0_pos = runner0_pos + 1
   runner0_pos = runner0_pos % (nb_pos - 1)
   runner_lpos = pos
end

function runner_0_loop(_main, npc)
   NpcGoToTbl(npc, runner0_tbl, Entity.new_func("runner_0_loop"))
end

function runner_0(_main, action)
   runner0_tbl = Entity.new_array()
   action = Entity.wrapp(action)
   local npc = main_widget.npcs[action[0]]
   runner_lpos = ywCanvasObjPos(npc.canvas)
   runner0_pos = 0
   :: again ::
   runner_0_mk_tbl(npc, "r0-", 7, "Runner_0")
   if runner0_pos ~= 0 then goto again end
   runner_0_loop(nil, npc)
   yeRemoveChild(main_widget.npc_act, action)
end

function sakai(_main, npc, name)
   npc = Entity.wrapp(npc)

   if (yuiRand() % 100 > 50) then
      c_place = "street3"
      npc._place = c_place
      push_to_ai_point("street3", "Runner_0", name)
   end
end

function move_npc(_wid, _useless, who, place, ai_point, forced)
   n = npcs[who]
   print(who, yeGetString(who))
   if forced then
      n._holded = 1
      n._place = nil
   end
   push_to_const_ai_point(yeGetString(place), yeGetString(ai_point), yeGetString(who))
end

function unmove_npc(_wid, _useless, who)
   n = npcs[who]
   n._holded = 1
   remove_const_ai_point(who)
end

function run_rat0(_main, action)
   runner0_tbl = Entity.new_array()
   action = Entity.wrapp(action)
   local npc = main_widget.npcs[action[0]]
   runner_lpos = ywCanvasObjPos(npc.canvas)
   runner0_pos = 0
   :: again ::
   runner_0_mk_tbl(npc, "rp", 5, "rat")
   --print("last pos:", runner_lpos, runner0_pos)
   if runner0_pos ~= 0 then goto again end
   runner_0_loop(nil, npc)
   yeRemoveChild(main_widget.npc_act, action)
end

function run_rat1(_main, _action)
   --print("run_rat1", action)
end
