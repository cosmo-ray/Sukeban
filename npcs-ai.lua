local phq = Entity.wrapp(ygGet("phq"))

local function push_to_ai_point_(map, p, name, check)
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
   return true
end

local function push_to_ai_point(map, p, name)
   return push_to_ai_point_(map, p, name, false)
end

function wouaf_ai(main, npc, name)
   local t = ygGetString("phq.env.time")

   if is_npc_ally(phq.pj, name) then
      if (t == "night") then
	 leave_team(name)
      end
   end
end

local ai_points = {
   ["school0"] = {
      {
	 ["p"] = "s0_3talk_0",
      },
      {
	 ["p"] = "s0_3talk_1",
      },
      {
	 ["p"] = "s0_3talk_2",
      },
      {
	 ["p"] = "s0_uw",
      }
   },
   ["street3"] = {
      {
	 ["p"] = "f0_t2_1",
      },
      {
	 ["p"] = "f0_t2_0",
      },
      {
	 ["p"] = "r_t2_0",
      },
      {
	 ["p"] = "r_t2_1",
      }
   }

}

function student_ai(main, npc, name)
   local t = ygGetString("phq.env.time")
   local c = ygGetInt("phq.env.chapter")
   local d = ygGetInt("phq.env.day")

   print("student_ai", name, c, d, t)
   if c ~= 1 then
      return
   end
   local cur_pos = name .. " House"

   if t == "morning" and d < 6 then
      local r = yuiRand() % 4
      if r == 0 then
	 cur_pos = "school0"
      elseif r == 1 then
	 cur_pos = "street3"
      else
	 -- find other place to be
	 -- also compute which class if still in class
      end
      print("School Time")
   elseif t == "night" then
      print("morning")
   elseif t == "day" then
      print("night")
   else
      print("fin de semaine !")
   end

   local csap = ai_points[cur_pos]
   if csap ~= nil then
      local idx = 1
      :: again ::
      if idx <= #csap
	 and push_to_ai_point_(cur_pos,
			       csap[idx].p,
			       name, true) == false then
	    idx = idx + 1
	    goto again
      end
   end
   print("yeGetIntAt(npc, 'is_random_student'): ", yeGetIntAt(npc, "is_random_student"),
	 yeGetIntAt(npc, "is_random_student") > 0, name)
   if yeGetIntAt(npc, "is_random_student") > 0 then
      Entity.wrapp(npc).dialogue = "neutral-student"
   end

   npc = Entity.wrapp(npc)
   npc.out_time = next_time()
   --print("ai of ", name, ":", Entity.wrapp(npc))
   --print("time: ", t, " chapter: ", c)
end

function bob_ai(main, npc, name)
   main = Entity.wrapp(main)
   npc = Entity.wrapp(npc)

   local c_place = "bob_house"
   local p = yuiRand() % 100

   if (p < 50) then
      c_place = "street3"
   end
   npc._place = c_place
   return student_ai(main, npc, name)
end

local runner_lpos = nil
local runner0_pos = 0
local runner0_tbl = nil

function runner_0_mk_tbl(npc, point_prefix, nb_pos, start_p)
   local pos = nil

   if runner0_pos < nb_pos - 2 then
      pos = main_widget.misc[point_prefix .. runner0_pos].rect
   else
      pos = main_widget.ai_point[start_p].rect
      ywPosAddXY(pos, 0, -50);
   end
   ywCanvasDoPathfinding(main_widget.mainScreen, runner_lpos, pos,
			 Pos.new(PIX_PER_FRAME * 1.2, PIX_PER_FRAME * 1.2).ent,
			 runner0_tbl)

   runner0_pos = runner0_pos + 1
   runner0_pos = runner0_pos % (nb_pos - 1)
   runner_lpos = pos
end

function runner_0_loop(main, npc)
   NpcGoToTbl(npc, runner0_tbl, Entity.new_func("runner_0_loop"))
end

function runner_0(main, action)
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

function sakai(main, npc, name)
   npc = Entity.wrapp(npc)

   push_to_ai_point("street3", "Runner_0", name)
end


function run_rat0(main, action)
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

function run_rat1(main, action)
   --print("run_rat1", action)
end
