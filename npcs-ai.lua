local phq = Entity.wrapp(ygGet("phq"))

function wouaf_ai(main, npc, name)
   local t = ygGetString("phq.env.time")

   print("wouaf AI", name)
   if is_npc_ally(phq.pj, name) then
      if (t == "night") then
	 leave_team(name)
      end
      print("wouaf wouaf !")
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
