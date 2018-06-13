local tiled = Entity.wrapp(ygGet("tiled"))
local lpcs = Entity.wrapp(ygGet("lpcs"))
local phq = Entity.wrapp(ygGet("phq"))
local modPath = Entity.wrapp(ygGet("phq.$path")):to_string()
local npcs = Entity.wrapp(ygGet("phq.npcs"))
local scenes = Entity.wrapp(ygGet("phq.scenes"))

function pushStatus(mn)
   local main = Entity.wrapp(ywCntWidgetFather(mn))

   ywCntPopLastEntry(main)
   local txt_screen = Entity.new_array()

   txt_screen["<type>"] = "text-screen"
   txt_screen["text-align"] = "center"
   txt_screen.text = "Status:\n" ..
      "life: " .. phq.pj.life:to_int() .. "\n" ..
      "alcohol level: " .. phq.pj.drunk:to_int()
   txt_screen.background = "rgba: 155 155 255 190"
   txt_screen.action = Entity.new_func("backToGameOnEnter")
   ywPushNewWidget(main, txt_screen)
   return YEVE_ACTION
end

function invList(mn)
   local main = Entity.wrapp(ywCntWidgetFather(mn))
   local inv = phq.pj.inventory
   ywCntPopLastEntry(main)
   mn = Menu.new_entity()
   mn:push("back to game", Entity.new_func("backToGame"))
   local i = 0
   while i < yeLen(inv) do
      mn:push(yeGetKeyAt(inv, i) .. ": " .. yeGetInt(inv[i]))
      i = i + 1
   end
   mn.ent.background = "rgba: 255 255 255 190"
   mn.ent.next = main.next
   ywPushNewWidget(main, mn.ent)   
end
