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
   local knowledge_str = "----- Knowledge -----\n"
   local knowledge = phq.pj.knowledge
   local stats_str = "----- Stats -----\n"
   local stats = phq.pj.stats

   local i = 0
   while i < yeLen(knowledge) do
      if knowledge[i] then
	 knowledge_str = knowledge_str ..
	    yeGetKeyAt(knowledge, i) .. ": " .. yeGetInt(knowledge[i]) .. "\n"
      end
      i = i + 1
   end
   local i = 0
   while i < yeLen(stats) do
      if stats[i] then
	 stats_str = stats_str ..
	    yeGetKeyAt(stats, i) .. ": " .. yeGetInt(stats[i]) .. "\n"
      end
      i = i + 1
   end

   txt_screen["<type>"] = "text-screen"
   txt_screen["text-align"] = "center"
   txt_screen.text = "Day: " ..
      DAY_STR[phq.env.day:to_int() + 1] .. ", " ..
      phq.env.time:to_string() .. ", " ..
      "week: " .. phq.env.week:to_string() .. "\n" ..
      "Status:\n" ..
      "life: " .. phq.pj.life:to_int() .. "\n" ..
      "alcohol level: " .. phq.pj.drunk:to_int() .. "\n" ..
      knowledge_str .. stats_str
   txt_screen.background = "rgba: 155 155 255 190"
   txt_screen.action = Entity.new_func("backToGameOnEnter")
   ywPushNewWidget(main, txt_screen)
   return YEVE_ACTION
end

function gmUseItem(mn)
   local main = Entity.wrapp(ywCntWidgetFather(mn))
   local cur = Entity.wrapp(ywMenuGetCurrentEntry(mn))
   local objs_list = phq.objects
   local o = objs_list[cur.obName:to_string()]
   print(objs_list:cent())
   if o.func then
      if yeType(o.func) == YFUNCTION then
	 o.func(main, o)
      else
	 yesCall(ygGet(o.func:to_string()), main:cent(), o:cent())
      end
   end
   print("use item !!", cur.obName,
	 objs_list[cur.obName:to_string()])
end

function invList(mn)
   local main = Entity.wrapp(ywCntWidgetFather(mn))
   local inv = phq.pj.inventory
   ywCntPopLastEntry(main)
   mn = Menu.new_entity()
   mn:push("back to game", Entity.new_func("backToGame"))
   local i = 0
   while i < yeLen(inv) do
      if inv[i] then
	 local cur = mn:push(yeGetKeyAt(inv, i) .. ": " ..
			     math.floor(yeGetInt(inv[i])),
			     Entity.new_func("gmUseItem"))
	 cur.obName = yeGetKeyAt(inv, i)
	 cur.inv_o = inv[i]
	 cur.inv = inv
      end
      i = i + 1
   end
   mn.ent.background = "rgba: 255 255 255 190"
   mn.ent.next = main.next
   ywPushNewWidget(main, mn.ent)
end
