local phq = Entity.wrapp(ygGet("phq"))
local drunk_txt = nil
local drunk_bar0 = nil
local drunk_bar1 = nil
local window_width = 800
local window_height = 600

is_end_of_chapter = false

function inter_bar_in(main)
   local c = Canvas.wrapp(main.mainScreen)
   local cc = c.ent

   drunk_txt = Entity.wrapp(
      ywCanvasNewTextExt(cc, 10, 10, Entity.new_string("Puke bar: "),
			 "rgba: 255 255 255 255"))
   drunk_bar0 = c:new_rect(100, 10, "rgba: 30 30 30 255",
			   Pos.new(200, 15).ent).ent
   drunk_bar1 = c:new_rect(100, 10, "rgba: 0 255 30 255",
			   Pos.new(200 * phq.pj.drunk / 100 + 1, 15).ent).ent
end

function inter_bar_out(main)
   local c = Canvas.wrapp(main.mainScreen)

   c:remove(drunk_txt)
   c:remove(drunk_bar0)
   c:remove(drunk_bar1)
end

function inter_bar_running(main)
   local c = Canvas.wrapp(main.mainScreen)
   local pjPos = Pos.wrapp(ylpcsHandePos(main.pj))
   local x0 = pjPos:x() - window_width / 2
   local y0 = pjPos:y() - window_height / 2

   ywCanvasObjSetPos(drunk_txt, x0 + 10, y0 + 10)
   ywCanvasObjSetPos(drunk_bar0, x0 + 100, y0 + 10)
   c:remove(drunk_bar1)
   drunk_bar1 = c:new_rect(x0 + 100, y0 + 10, "rgba: 0 255 30 255",
			   Pos.new(200 * phq.pj.drunk / 100 + 1, 15).ent).ent
   print(phq.pj.drunk, " > ", 80)
   if phq.pj.drunk > 80 then
      -- I could do that the smart & clean way, create a json just for the scene
      -- But But But, woult it be more clean ????
      -- the more I code the more I think that clean way are actualy
      -- a lot more crappy that fast and dirty
      -- at last here you have everything you need to know about puke quest ending

      local vn_quest_end = Entity.new_array()
      local dial = nil

      vn_quest_end[0] = Entity.new_array()
      -- 1rst dialogue
      dial = vn_quest_end[0]
      dial.text = "YES\n"..
	 "You had it\n"..
	 "You was ready to acomplish Heeru QUEST\n"..
	 "You appoch your target\n"..
	 "take a deep breath\n"..
	 "You watch the bastard that had commit great dishonner to Herru\n"..
	 "look on his fase, it was all blury\n"..
	 "haha it's funny\n"..
	 "Wowwww maybe I'm a little tipsy\n"..
	 "THEN YOU PUKE ON HIS UGLY HEAD !!!\n" ..
	 "- DON'T PUKE ON HEERRRRUUUU NEXT TIME  !\n"..
	 "you said to him...\nthen you leave...\n"..
	 "But on your way home, you realise that ground is waving\n"..
	 "the kind of wave that make you seesick..."

      dial.answer = {}
      dial.answer.text = "(tatata)"
      dial.answer.actions = {}
      dial.answer.actions[0] = {}
      dial.answer.actions[1] = {}
      dial.answer.actions[2] = {}
      local a0 = dial.answer.actions[0]
      a0[0] = "setInt"
      a0[1] = "phq.quests.a_drunk_story"
      a0[2] = 1
      local a1 = dial.answer.actions[1]
      a1[0] = "phq.changeScene"
      a1[1] = "street4"
      a1[2] = 1
      local a2 = dial.answer.actions[2]
      a2[0] = "phq.phs_start"

      vnScene(main, nil, vn_quest_end)
   end
end

local charle_body_guard_leave_t = nil

function charle_body_guard_leave(main, dialogue_wid)
   if dialogue_wid then
      print("init leave")
      backToGame(dialogue_wid)
      main.block_script = "charle_body_guard_leave"
      pushPjLeave(main.npcs["Thrug 0"], 1)
      pushPjLeave(main.npcs["Thrug 1"], 1)
      charle_body_guard_leave_t = YTimerCreate()
   end
   local t = YTimerGet(charle_body_guard_leave_t)
   print("charle_body_guard_leave !!!!", YTimerGet(charle_body_guard_leave_t))
   if t > 2500000 then
      main.block_script = nil
      startDialogue(main, main.npcs["Charle"], Entity.new_string("Lonely Charle"))
   end
end

function chapter_1_sleep(main)
   if phq.env.time:to_string() == "morning" and
      phq.env.day < 6
   then
      main.cant_skip_time = true
      cant_skip_time_reason = "must go to school"
   else
      main.cant_skip_time = false
      cant_skip_time_reason = nil
   end
end

function chapter_1(main)
   main.sleep_script = "chapter_1_sleep"
   local s = Entity.new_array()
   s[0] = GM_STATS_IDX
   s[1] = Entity.new_func("chapter_1_menu")
   yePushBack(main.gmenu_hook, s)
end

function morning_class(mn)
   print("I'm at school, yayyyyyy")
   local f_mn = ywCntWidgetFather(mn)

   backToGame(f_mn)
   main_widget.cant_skip_time = 0
   print(main_widget.cant_skip_time)
   advance_time(main_widget, "school0", true)
end

function chapter_1_menu(main, mn)
   local mn = Menu.wrapp(mn)
   if phq.env.time:to_string() == "morning" and phq.env.day < 6 then
      mn:push("go to morning class", Entity.new_func("morning_class"))
   end
   print("\nchapter_1_menu!!!!!\n", main, mn)
end


local function gen_school()
   local FEMALE = 1
   local MALE = 2

   print("gen_school")
   local sexes = {"female", "male"}

   local array_name = {
      {"Georgette", "Michelle", "Germaine", "Lynda", "Clemence", "Camille",
       "Geraldine", "Fraise", "Anna", "Hanna", "Mya", "Francoise",
       "Fleur", "Alice", "Petra", "Geunievre", "Oscar", "Helena", "Louise"},
      {"Raoul", "Asran", "Tibault", "Adrien", "George", "Linus", "Richard",
       "Geraldine", "Ragnar", "Sigure", "Nicolas", "Eric", "Francois",
       "Camille", "Matthias", "Perceval", "Harry", "Oscar", "Amed",
       "Mohamed", "Michelle"}
   }

   local last_name = {
      "Georette", "Michelle", "Germaine", "Lynda", "Clemence",
      "Geraldine", "Fraise", "Raoul", "Asran", "Tibeau",
      "Adrien", "George", "Du-champs", "Tomodachi", "Ichogo", "Troie",
      "Hero", "Determinated", "Peacecraft", "Warmaker", "Neko",
      "Geraldine", "Fraise", "Cat", "Sed", "Weechat", "Archer",
      "Linus", "Richard", "Stallman", "Armstrong", "Char", "Aznabulu",
      "Tomino", "Osamu", "Dezaki", "Jacouille", "Francois De jarjay"
   }

   local types = {
      {"light", "dark", "dark2", "woman-black", "woman-white",
       "woman-olive", "woman-peach"},
      {"light", "dark", "dark2", "man-black", "man-white", "man-olive",
       "man-peach"}
   }

   local hair_type = {
	 "plain", "loose", "bangs", "bangslong", "bangslong2", "bangsshort",
	 "bedhead", "bunches", "jewfro", "long", "longhawk", "longknot",
	 "loose", "messy1", "messy2", "mohawk", "page", "page2", "parted",
	 "pixie", "plain", "ponytail", "ponytail2", "princess", "shorthawk",
	 "shortknot", "shoulderl", "shoulderr", "swoop", "unkempt", "xlong",
	 "xlongknot"
   }

   local hair_color = {
      "black", "redhead2", "redhead", "blonde", "blonde2", "blue",
      "blue2", "brown", "brown2", "brunette", "brunette2", "dark-blonde",
      "gold", "gray", "gray2", "green", "green2", "light-blonde",
      "light-blonde2", "pink", "pink2", "purple", "raven", "raven2",
      "ruby-red", "white-blonde", "white-blonde2", "white-cyan",
      "white"
   }

   local torso = {
      {"white_sleeveless", "robe_purple", "robe_black", "robe_white",
       "white_pirate", "Black Leather blouse", "blue_vest", "s_green_dress",
       "tightdress_lightblue", "teal_pirate", "teal_sleeveless",
       "white_sleeveless", "white_tunic"},
      {"white longsleeve m"}
   }

   local legs = {
      {"long skirt", "short skirt", "legion skirt", "teal pants female",
       "white pants female"},
      {"teal pants m"}
   }

   local feet = {
      {"brown_shoes", "black_slippers", "maroon longboot", "black_shoes"},
      {"brown_shoes m"}
   }

   if (yIsNNil(yeGet(phq.env.school, "is_gen"))) then
      return
   end
   phq.env.school = {}
   local s = phq.env.school
   s.is_gen = 1
   s.students = {}
   local stds = s.students
   for i = 0, yeLen(npcs) - 1 do
      local npc = yeGet(npcs, i)
      local npc_key = yeGetKeyAt(npcs, i)

      if yIsNNil(yeGet(npc, "student_year")) then
	 yePushBack(s.students, npc, npc_key)
	 if (yIsNil(yeGet(npc, "class"))) then
	    yeCreateInt(yuiRand() % 3, npc, "class")
	 end
      end
   end

   for i = 0, 10 do
      :: again ::
      local gender =  yuiRand() % 2 + 1
      local name_table = array_name[gender]
      local name = rand_array_elem(name_table) .. " " ..
	 rand_array_elem(last_name)

      if npcs[name] then goto again end

      local n = Entity.new_array(npcs, name)
      n.sex = sexes[gender]
      n.type = rand_array_elem(types[gender])
      n.class = yuiRand() % 3
      n.student_year = yuiRand() % 3 + 1
      local hair = Entity.new_array(n, "hair")
      hair[0] = rand_array_elem(hair_type)
      hair[1] = rand_array_elem(hair_color)
      yePushBack(s.students, n, name)
      -- clothes still needed
      local eq = Entity.new_array(n, "equipement")
      eq.torso = rand_array_elem(torso[gender])
      eq.legs = rand_array_elem(legs[gender])
      eq.feet = rand_array_elem(feet[gender])

      dressUp(n)
   end
end

function end_chapter_0(main)
   print("end_chapter_0")
   if yIsNil(main.sleep_script) then
      main.sleep_script = "end_chapter_0"
      is_end_of_chapter = true
      return
   end
   print("then ?")
   if phq.env.day:to_int() == 7 and
   phq.env.time:to_string() == "night" then
      is_end_of_chapter = false
      main.sleep_script = nil
      phq.env.chapter = 1
      phq.quests.school_1_semestre = 1
      for i = 0, yeLen(npcs) do
	 local n = npcs[i]

	 if yIsNil(n) or yeGetIntAt(n, "student_year") < 1 then
	    goto skip
	 end

	 if yIsNil(yeGet(n, "ai")) then
	    yeCreateString("student_ai", n, "ai")
	 end

	 if yIsNil(yeGet(n, "class")) then
	    yeCreateInt(yuiRand() % 3, n, "class")
	 end

	 print("n: ", yeGetIntAt(n, "class"),
	       yeGetStringAt(n, "ai"), yeGet(n, "class"),
	       yIsNil(yeGet(n, "class")), yeGet(n, "ai"),
	       yIsNil(yeGet(n, "ai")))
	 :: skip ::
      end


      main.sleep_loc = "house1"
      local vn_quest_end = Entity.new_array()

      vn_quest_end[0] = Entity.new_array()
      gen_school()
      -- 1rst dialogue
      local dial = vn_quest_end[0]
      dial.text = "Tin tin....\n" ..
	 "ttin tin tin tin tin tin tin tin tinnn, tinnnnn\n" ..
	 "The Dawn is especially crude this morning\n" ..
	 "you wake up wih the reaisationt that the holiday are over\n" ..
	 "and you have to go to a new school\n" ..
	 "where you know only a few peoples\n"

      dial.answer = {}
      dial.answer.text = "Gather your books before venturing for"
      dial.answer.action = "phq.backToGame"

      vnScene(main, nil, vn_quest_end)
   end
end

scripts = {}
scripts["inter_bar_in"] = inter_bar_in
scripts["inter_bar_out"] = inter_bar_out
scripts["inter_bar_running"] = inter_bar_running
scripts["charle_body_guard_leave"] = charle_body_guard_leave
scripts["end_chapter_0"] = end_chapter_0
scripts["chapter_1"] = chapter_1
scripts["chapter_1_sleep"] = chapter_1_sleep
