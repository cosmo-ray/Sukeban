function student_ai(main, npc)
   print("ai of :", Entity.wrapp(npc))
end

function bob_ai(main, npc)
   main = Entity.wrapp(main)
   npc = Entity.wrapp(npc)

   local c_place = "bob_house"
   local p = yuiRand() % 100

   if (p < 50) then
      c_place = "street3"
   end
   npc._place = c_place
   return student_ai(main, npc)
end
