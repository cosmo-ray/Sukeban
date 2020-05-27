local phq = Entity.wrapp(ygGet("phq"))

function wouaf_ai(main, npc, name)
   local t = ygGetString("phq.env.time")

   if is_npc_ally(phq.pj, name) then
      if (t == "night") then
	 leave_team(name)
      end
   end
end

function student_ai(main, npc, name)
   local t = ygGetString("phq.env.time")
   local c = ygGetInt("phq.env.chapter")
   local d = ygGetInt("phq.env.day")

   if c ~= 1 then
      return
   end
   if t == "morning" and d < 6 then
      print("School Time")
   elseif t == "night" then
      print("morning")
   elseif t == "day" then
      print("night")
   else
      print("fin de semaine !")
   end

   print("ai of ", name, ":", Entity.wrapp(npc))
   print("time: ", t, " chapter: ", c)
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

local function push_to_ai_point(map, p, name)
   if phq.env.ai_point == nil then
      phq.env.ai_point = {}
   end
   if phq.env.ai_point[map] == nil then
      phq.env.ai_point[map] = {}
   end
   phq.env.ai_point[map][p] = name
end

local runner0_nb_pos = 7
local runner_lpos = nil
local runner0_pos = 0
local runner0_tbl = nil

function runner_0_mk_tbl(npc)
   local pos = nil

   if runner0_pos < runner0_nb_pos - 2 then
      pos = main_widget.misc["r0-" .. runner0_pos].rect
   else
      pos = main_widget.ai_point["Runner_0"].rect
      ywPosAddXY(pos, 0, -50);
   end
   ywCanvasDoPathfinding(main_widget.mainScreen, runner_lpos, pos,
			 Pos.new(PIX_PER_FRAME * 4, PIX_PER_FRAME * 4).ent,
			 runner0_tbl)

   runner0_pos = runner0_pos + 1
   runner0_pos = runner0_pos % (runner0_nb_pos - 1)
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
   runner_0_mk_tbl(npc)
   if runner0_pos ~= 0 then goto again end
   runner_0_loop(nil, npc)
   yeRemoveChild(main_widget.npc_act, action)
end

function sakai(main, npc, name)
   npc = Entity.wrapp(npc)

   push_to_ai_point("street3", "Runner_0", name)

   -- if name is not null, then it's call from advence time
   if main_widget.cur_scene_str:to_string() == "street3" then
      local action = Entity.new_array(main_widget.npc_act)
      action[0] = name
      action.controller = Entity.new_func("runner_0")
   end
end
