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

local phq = Entity.wrapp(ygGet("phq"))
local drunk_txt = nil
local drunk_bar0 = nil
local drunk_bar1 = nil
local window_width = 800
local window_height = 600

local SKIP_CLASS_SCENE = false

BLOCK_EVE_NO_UNSET = 10

block_events = Entity.new_array()

school_students_organisation = {
   "Computer club",
   "Animu Club",
   "Student Club",
   "Beautification Club",
   "Students Protection Group",
   "Music club",
   "Mystical Neet Go-under",
   "Board Game and Roleplay Club"
}

function is_concert_at_wheelball()
   print("is_concert_at_whellball !\n", phq.env.day,
	 phq.env.time:to_string())
   if phq.env.day > 5 and phq.env.time:to_string() == "night" then
      return Y_TRUE
   end
   return Y_FALSE

end

function chk_affection_subchar(pj_char, npc_char, multipliyer)
   local base = 0
   for i = 0, yeLen(npc_char) - 1 do
      local tk = yeGetKeyAt(npc_char, i)
      local tki = yeGetIntAt(npc_char, i)
      local pjt = pj_char[tk]
      if yeGetInt(pjt) ~= 0 and tki ~= 0 then
	 pjt = yeGetInt(pjt)
	 if pjt > 0 and tki > 0 or pjt < 0 and tki < 0 then
	    pjt = yuiAbs(pjt)
	    tki = yuiAbs(tki)

	    if pjt > tki then
	       base = base + (tki * multipliyer)
	    else
	       base = base + (pjt * multipliyer)
	    end
	 else
	    pjt = yuiAbs(pjt)
	    tki = yuiAbs(tki)

	    if pjt > tki then
	       base = base - (tki * multipliyer)
	    else
	       base = base - (pjt * multipliyer)
	    end
	 end
      end
   end
   return base
end

-- "stalk": "phq.quests.give_letter",
-- "{phq.quests._give_letter.from} want me to give a letter to {phq.quests._give_letter.to}",

function give_neutral_quest(a0, a1, box)
   local TOT_NEUTRAL_QST = 2
   local which_quest = yuiRand() % TOT_NEUTRAL_QST
   local dial = Entity.wrapp(yDialogueCur(a0))
   local src = Entity.wrapp(ygGet("phq_wid.dialogue_npc"))

   if which_quest == 0 then
      local target = students[yuiRand() % yeLen(students)]
      while yeGetString(target.name) == yeGetString(src.name) do
	 target = students[yuiRand() % yeLen(students)]
      end

      phq.quests._give_letter = {}
      phq.quests._give_letter.from = src.name
      phq.quests._give_letter.to = target.name
      print(src.name, target.name)
      dial.text = "{phq.quests._give_letter.from} ask you to give letter to {phq.quests._give_letter.to}!"
      phq.quests.give_letter = 0
      yePrint(dial)
   else
      local what = "wristband" -- need to be choose depending on src persnality

      phq.quests._find_stuff = {}
      phq.quests._find_stuff.from = src.name
      phq.quests._find_stuff.what = what
      phq.quests._find_stuff.where = (yuiRand() % 4 + 1)
      phq.quests.find_stuff = 0
      dial.text = "{phq.quests._find_stuff.from} ask you to help per find pers {phq.quests._find_stuff.what}!"
   end
   dial.answers = {}
   local answers = dial.answers
   answers[0] = {}
   answers[0].actions = {}
   local actions = answers[0].actions
   actions[yeLen(actions)] = "phq.backToGame"
   answers[0].text = "(accept {phq_wid.dialogue_npc.name} task)"
end

function chk_affection(wid)
   print(wid)
   print(dialogue_npc.trait, "\nvs\n", phq.pj.trait)
   -- base: charm
   -- 4 % per common club
   -- 30 % reputation x trait
   -- 20 % common trait
   -- 25 % common knowledge
   -- 3 % if gender attraction based of charm

   local pj = phq.pj
   local roll = yuiRand() % 100
   local charm = phq.pj.stats.charm:to_int()
   if yIsNil(dialogue_npc.relation) then
      dialogue_npc.relation = {}
   end
   local base_affect = math.floor(yeGetInt(dialogue_npc.relation.affection) / 4)
   local base = (charm * 2) + 4 + base_affect
   local n_traits = dialogue_npc.trait

   if charm > 2 and n_traits.female_atraction > 0 then
      if charm < 4 then
	 base = base + 2
      elseif charm < 6 then
	 base = base + 4
      else
	 base = base + 6
      end
   end

   local pj_traits = pj.trait
   base = base + chk_affection_subchar(pj_traits, n_traits, 1)
   base = base + chk_affection_subchar(pj.knowledge, dialogue_npc.knowledge, 2)

   local n_rep = dialogue_npc.reputation
   local pj_rep = pj.reputation

   if yIsNil(n_rep) then
      n_rep = Entity.new_array()
   end

   if (n_rep.glandeur and n_rep.glandeur > 0 and pj_traits.lazy > 0) or
      (pj_rep.glandeur > 0 and n_traits.lazy and n_traits.lazy > 0) then
      base = base + 2
   end

   -- to be honest this one is slitghly more complex, because a lot of peoples tend to hate
   -- what they are atracted to. if they considere this sameful.
   if pj_rep.slut > 0 and n_traits.perv and n_traits.perv > 0 then
      base = base + 2
   end

   if (n_rep.bully and n_rep.bully > 0 and pj_traits.violance > 0) or
      (pj_rep.bully > 0 and n_traits.violance and n_traits.violance > 0) then
      base = base + 2
   end

   local organisations = dialogue_npc.organisations
   local pj_o = pj.organisations
   for i = 0, yeLen(organisations) - 1 do
      local ostr = yeGetStringAt(organisations, i)
      for j = 0, yeLen(pj_o) - 1 do
	 if ostr == yeGetStringAt(pj_o, j) then
	    base = base + 5
	    goto continu_loop
	 end
      end
      :: continu_loop ::
   end

   print("end base:" , base, " roll: ", roll)
   -- uncomment V to tests quests system
   -- if 1 then return 4 end
   if roll == 0 then
      print("critical sucess")
      return 2
   elseif roll > 98 then
      print("critical failure")
      return 3
   elseif roll > base then
      print("go bad @")
      return 1
   end
   roll = yuiRand() % 100
   if roll < 50 then
      print("go give quest")
      return 4
   end
   print("go pas bad !")
   return 0
end

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
      local dial

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

function chapter_2_vacation()
   print("Vacation ALONE !!!")
   local s = Entity.new_array()
   s[0] = GM_STATS_IDX
   s[1] = Entity.new_func(chapter_2_menu)
   yePushBack(main_widget.gmenu_hook, s)
end

-- chapter is school stuff again, like in chapter 1
function chapter_3()
   main_widget.sleep_script = "chapter_1_sleep"
   local s = Entity.new_array()
   s[0] = GM_STATS_IDX
   s[1] = Entity.new_func(chapter_1_menu)
   yePushBack(main_widget.gmenu_hook, s)
end

function chapter_1(main)
   main.sleep_script = "chapter_1_sleep"
   local s = Entity.new_array()
   s[0] = GM_STATS_IDX
   s[1] = Entity.new_func(chapter_1_menu)
   yePushBack(main.gmenu_hook, s)
end

local function end_morning_class()
   print("WESH !!!!!!")
   advance_time(main_widget, "school0", true)
   phq.env.school_day = phq.env.school_day + 1
end

local game_scene_state = 0
local game_scene_timer = 0
local game_scene_npcs = Entity.new_array() -- this will never be free :(

local function game_scene_do_timer(t)
   if game_scene_timer < t then
      game_scene_timer = game_scene_timer + ywidTurnTimer() / 1000
      return BLOCK_EVE_NO_UNSET
   end
   game_scene_timer = 0
   game_scene_state = game_scene_state + 1
   return BLOCK_EVE_NO_UNSET
end

local function game_scene(_wid, _eve, scene_str)
   local scenes = ygGet("phq.game_senes")
   local scene = Entity.wrapp(yeGet(scenes, yeGetString(scene_str)))

   if yIsNil(scene) or yIsNil(scene[game_scene_state]) then
      yeClearArray(game_scene_npcs)
      game_scene_timer = 0
      game_scene_state = 0
      return 0
   end

   local cs = scene[game_scene_state]
   local csa = cs.action:to_string()
   local timer = yeGetIntAt(cs, "timer")
   local pos = nil

   if cs["force-pos"] then
      pos = cs["force-pos"]
   elseif cs["npc-pos"] then
      pos = yGenericHandlerPos(main_widget.npcs[cs["npc-pos"]])
   end

   local start = 0
   if timer ~= 0 then
      start = -timer + 500
   end

   if csa == "change-scene" then
      local dir = cs.direction
      changeScene(main_widget, nil, cs.scene, Entity.new_int(0))
      ylpcsHandlerSetPos(main_widget.pj, pos)
      if dir ~= nil then
	 lpcs.handlerSetOrigXY(main_widget.pj, 0, lpcsStrToDir(yeGetString(dir)))
	 yGenericHandlerRefresh(main_widget.pj)
      end
      reposeCam(main_widget, main_widget.pj)
   elseif csa == "advance-time" then
      local s = yeGetString(cs.scene)

      advance_time(main_widget, s, true, pos)
   elseif csa == "timer" then
      return game_scene_do_timer(timer)
   elseif csa == "move-cam" then
      reposeCam(main_widget, main_widget.pj, yeGetIntAt(cs.mov, 0), yeGetIntAt(cs.mov, 1))
   elseif csa == "place-students" then
      local studs = cs.students
      for i = 0, yeLen(studs) - 1 do
	 local npc = studs[i]
	 local npcp = Pos.new(yeGetIntAt(npc, 0), yeGetIntAt(npc, 1))
	 local sy = yeGetIntAt(npc, 2)
	 local sc = yeGetIntAt(npc, 3)
	 local scid = yeGetIntAt(npc, 4)
	 local npcn, s = find_student(sy, sc, scid)
	 if s ~= nil then
	    local npcd = lpcsStrToDir(yeGetStringAt(npc, 5))
	    local n = push_npc(npcp, npcn, npcd)

	    yePushBack(game_scene_npcs, n)
	 end
      end
   elseif csa == "remove-npc" then
      local id = yeGetInt(cs.id)

      yGenericHandlerNullify(game_scene_npcs[id])
      game_scene_npcs[id] = nil
   elseif csa == "place-npcs" then
      local npcs = cs.npcs

      for i = 0, yeLen(npcs) - 1 do
	 local npc = npcs[i]
	 local npcp = Pos.new(yeGetIntAt(npc, 0), yeGetIntAt(npc, 1))
	 local npcn = yeGetStringAt(npc, 2)
	 local npcd = lpcsStrToDir(yeGetStringAt(npc, 3))
	 local n = push_npc(npcp, npcn, npcd)

	 yePushBack(game_scene_npcs, n)
      end
   elseif csa == "small-talk" then
      local txt = yeGetString(cs.txt)

      print("small-talk:", txt)
      pushSmallTalk(txt, yeGetIntAt(pos, 0), yeGetIntAt(pos, 1), start)
   elseif csa == "yirl-action" then
      local a = cs.yaction

      ywidAction(a, main_widget, nil)
   elseif csa == "tmp-image" then
      local path = yeGetString(cs.path)
      local img = ywCanvasNewImgByPath(main_widget.upCanvas, ywPosX(pos),
				       ywPosY(pos), path)
      local reduce = yeGetIntAt(cs, "reduce-%")
      local img_time = yeGetIntAt(cs, "img-time")

      if img_time ~= 0 then
	 start = -img_time + 500
      end

      if reduce ~= 0 then
	 ywCanvasPercentReduce(img, reduce)
      end
      pushTmpCanvasObj(img, start)
   elseif csa == "set" then
      -- I should check for other types
      print("b set at:", yeGetStringAt(cs, "variable"))
      yePrint(ygGet(yeGetStringAt(cs, "variable")))
      ygReCreateInt(yeGetStringAt(cs, "variable"), yeGetIntAt(cs, "value"))
      print("set at:", yeGetStringAt(cs, "variable"))
      yePrint(ygGet(yeGetStringAt(cs, "variable")))
   elseif csa == "recreate-string" then
      -- I should check for other types
      ygReCreateString(yeGetStringAt(cs, "variable"), yeGetStringAt(cs, "value"))
   end

   if timer ~= 0 then
      cs.action = "timer"
      return BLOCK_EVE_NO_UNSET
   end
   game_scene_state = game_scene_state + 1
   return BLOCK_EVE_NO_UNSET
end

function start_game_scene(_wid, _eve, scene_str)
   yeClearArray(block_events)
   local a = Entity.new_array(block_events)

   Entity.new_func(game_scene, a)
   yePushBack(a, scene_str)
end

function morning_class(mn)
   print("I'm at school, yayyyyyy", phq.env.school_day)
   print(phq.env.school_day, phq.env.school_day > 26)
   print(yeGetInt(phq.env.school_day), yeGetInt(phq.env.school_day) % 2)
   print(phq.env.chapter < 2)
   if phq.env.school_day > 26 and yeGetInt(phq.env.school_day) % 2 == 1 and
      phq.env.chapter < 2 then
      phq.env.school_day = phq.env.school_day + 1
      phq.events.is_blockus = 1
      advance_time(main_widget, "street3", true)
      main_widget.cant_skip_time = 0
      backToGame2()
      vnScene(main_widget, nil, "blockus")
      return
   end
   if phq.env.school_day < 30 and phq.env.chapter > 2 then
      phq.events.saki_presentaion = 1 -- this is to ensure we can end the game
      phq.env.school_day = 30
   end
   local f_mn = ywCntWidgetFather(mn)
   local school_day = phq.env.school_day:to_int()

   yeClearArray(block_events)

   if SKIP_CLASS_SCENE == true then
      goto mid_skip
   end

   -- this block is for events before class
   if school_day == 0 then
      local a = Entity.new_array(block_events)

      Entity.new_string("phq.vnScene", a)
      Entity.new_string("school_presentation", a)

      a = Entity.new_array(block_events)
      Entity.new_func(game_scene, a)
      Entity.new_string("school_intro", a)
   end

   :: mid_skip ::

   local class_a = Entity.new_array(block_events)

   if SKIP_CLASS_SCENE == true then
      goto finalize
   end

   Entity.new_string("phq.vnScene", class_a)
   Entity.new_string("class", class_a)

   print("HUM HUM: ", school_day)
   -- this block is for events after class
   if school_day == 1 then
      local a = Entity.new_array(block_events)

      Entity.new_func(game_scene, a)
      Entity.new_string("baffy_talk", a)
   elseif school_day == 2 then
      local a = Entity.new_array(block_events)

      Entity.new_func(game_scene, a)
      -- Fight you can't win !
      -- Akira show his super skill
      Entity.new_string("akira_fight", a)
   elseif school_day == 5 then
      local a = Entity.new_array(block_events)

      Entity.new_func(game_scene, a)
      Entity.new_string("saki intro", a)
   elseif school_day == 7 then
      local a = Entity.new_array(block_events)

      Entity.new_func(game_scene, a)
      Entity.new_string("saki 1rst meeting", a)
   elseif school_day == 8 then
      local a = Entity.new_array(block_events)

      Entity.new_func(game_scene, a)
      Entity.new_string("prot_club_mission_0", a)
   elseif school_day == 35 then
      local a = Entity.new_array(block_events)
      print("HELLLLOOOO !!!!!!!!")

      Entity.new_func(game_scene, a)
      Entity.new_string("end_events", a)
   end
   :: finalize ::

   if school_day > 10 and phq.env.chapter < 2 then
      phq.env.is_end_of_chapter = 1
   elseif school_day > 35 then
      phq.env.is_end_of_chapter = 1
   end

   Entity.new_func(end_morning_class, block_events)

   backToGame(f_mn)
   main_widget.cant_skip_time = 0
end

function chapter_2_menu(main, mn)
   mn = Menu.wrapp(mn)
   -- this could be improved a lot
   mn:push("spend winter vacation alone", Entity.new_func(gotoEndChapter))
end

function chapter_1_menu(main, mn)
   mn = Menu.wrapp(mn)
   if phq.env.time:to_string() == "morning" and phq.env.day < 6 then
      mn:push("go to morning class", Entity.new_func(morning_class))
   end
   print("\nchapter_1_menu!!!!!\n", main, mn)
end


local function check_img_cndition(cnd, npc)
   if cnd == nil then
      return true
   end
   if cnd.max_charm ~= nil and npc.stats.charm > cnd.max_charm then
      return false
   end
   if cnd.min_charm ~= nil and npc.stats.charm < cnd.min_charm then
      return false
   end
   return true
end

function find_student(year, class, class_id)
   local students = phq.env.school.students

   for i = 0, yeLen(students) - 1 do
      s = students[i]
      if s and s.student_year:to_int() == year and
	 s.class:to_int() == class and
      s.class_id:to_int() == class_id then
	 return yeGetKeyAt(students, i), s
      end
   end
   return nil
end

local function gen_school()
   if (yIsNNil(yeGet(phq.env.school, "is_gen"))) then
      return
   end

   local FEMALE = 1
   local MALE = 2

   print("gen_school")
   local sexes = {"female", "male"}
   local avaible_house = {"rand_student_house_l"}
   local avaible_house_idx = 1

   local array_name = {
      {"Georgette", "Michelle", "Germaine", "Lynda", "Clemence", "Camille",
       "Geraldine", "Fraise", "Anna", "Hanna", "Mya", "Francoise",
       "Fleur", "Alice", "Petra", "Geunievre", "Oscar", "Helena", "Louise",
       "Kim", "Agustina", "Codel", "Lisette", "Athena", "Georette", "Isis",
       "Charlotte", "Carole", "Caroline", "Linette", "Caterine", "Olivia",
       "Yuki", "Anako", "Geromine", "Gwenegann", "Katyusha", "Olya",
       "Pascaline", "Olga", "Veronic", "Cassandre", "Rose", "Emilie", "Kira",
       "Alise", "Alita", "Oka", "Lea", "Leah", "Jacky", "Claudia", "Cesar", "Ulis",
       "Alexandra", "Matilde", "Matilda", "Alex", "Alix", "France", "Francine",
       "Chantalle", "Lucy", "Luciolla", "Marie", "Maël"},
      {"Raoul", "Asran", "Tibault", "Adrien", "George", "Linus", "Richard",
       "Geraldine", "Ragnar", "Sigure", "Nicolas", "Eric", "Francois",
       "Camille", "Matthias", "Perceval", "Harry", "Oscar", "Amed", "Jean",
       "Mohamed", "Michelle", "Arthur", "Romain", "Benjamin", "Akira", "Mars",
       "Bill", "Charle", "Romain", "Thomas", "Mehdi", "Olivie", "Gerome", "Caradoc",
       "Jean Pierre", "Jean Charle", "Pascale", "Rogger", "Dany", "Raz", "Cassandre",
       "Kira", "Lee", "Jacky", "Didier", "Claud", "Axel", "Mickael", "Mathias",
       "Mattias", "Alex", "Alexie", "Francky", "Vincent", "Pierre", "Ali", "Luc",
       "Luciolla", "Marco"}
   }

   local last_name = {
      "Georette", "Michelle", "Germaine", "Lynda", "Clemence",
      "Geraldine", "Fraise", "Raoul", "Asran", "Tibeau",
      "Adrien", "George", "Du-champs", "Tomodachi", "Ichogo", "Troie",
      "Hero", "Determinated", "Peacecraft", "Warmaker", "Neko",
      "Geraldine", "Fraise", "Cat", "Sed", "Weechat", "Archer",
      "Linus", "Richard", "Stallman", "Armstrong", "Char", "Aznabulu",
      "Tomino", "Osamu", "Dezaki", "Jacouille", "Francois De jarjay",
      "Kanzaki", "Le Francais", "Coucou", "Mars", "Szabo", "Bookseller",
      "Manualreader", "Mac Ross", "Squirel", "Backdoor", "Adlez", "Harissa",
      "Anako", "Geromine", "Gwenegann", "Noir", "Katyusha", "Poireau",
      "Articho", "Ananas", "Anko", "Polenarefu", "Hopson", "Who", "Rose",
      "De Paname", "De la Tour", "Kira", "Yamato",  "Trentehein", "Compute",
      "Ordinateur", "Robots", "Robie", "Vincent", "Pierre", "Metal", "King",
      "Queen", "Zuldo", "Alibaba", "Baba", "Bibi", "Chirac", "Chonson", "Lac",
      "Luciolle", "Firefly", "Grave"
   }

   local types = {
      {"light", "dark", "dark2", "woman-black", "woman-white",
       "woman-olive", "woman-peach"},
      {"light", "dark", "dark2", "man-black", "man-white", "man-olive",
       "man-peach"}
   }

   local hair_type = {
      {
	 "plain", "loose", "bangs", "bangslong", "bangslong2", "bangsshort",
	 "bedhead", "bunches", "jewfro", "long", "longhawk", "longknot",
	 "loose", "messy1", "messy2", "mohawk", "page", "page2", "parted",
	 "pixie", "plain", "ponytail", "ponytail2", "princess", "shorthawk",
	 "shortknot", "shoulderl", "shoulderr", "swoop", "unkempt", "xlong",
	 "xlongknot"
      },
      {
	 "plain", "loose", "bangs", "bangslong", "bangslong2", "bangsshort",
	 "bedhead", "jewfro", "long", "longhawk", "longknot",
	 "loose", "messy1", "messy2", "mohawk", "page", "page2", "parted",
	 "plain", "princess", "shorthawk", "pixie",
	 "shortknot", "swoop", "unkempt", "xlong",
	 "xlongknot"
      }
   }

   local hair_color = {
      "black", "black", "black", "black", "blonde", "blonde",
      "redhead2", "redhead", "blonde", "blonde2", "blue",
      "blue2", "brown", "brown2", "brunette", "brunette2", "dark-blonde",
      "gold", "gray", "gray2", "green", "green2", "light-blonde",
      "light-blonde2", "pink", "pink2", "purple", "raven", "raven2",
      "ruby-red", "white-blonde", "white-blonde2", "white-cyan",
      "white", "raven", "raven2", "raven", "raven2", "raven", "raven2"
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

   local usable_imgs = {
      {MALE, "light", {
	  ["src"] = "imgs/DF_Neutral.png",
	  ["hair-color"] = "redhead",
	  ["reduce"] = 50
       },
       false, {
	  ["min_charm"] = 2,
	      }
      },
      {FEMALE, "dark", "imgs/agustina.png", false},
      {FEMALE, "woman-olive", "imgs/random_brown.png", false},
      {FEMALE, "light", {
	  ["src"] = "imgs/Codel4.png",
	  ["reduce"] = 50},
       false},
      {FEMALE, "light", {
	  ["src"] = "imgs/199.png",
	  ["reduce"] = 50},
       false, {
	  ["max_charm"] = 0,
	      }
      },
      {FEMALE, "light",
       { ["src"] = "imgs/saki_normal.png",
	  ["reduce"] = 20,
	  ["threshold"] = {0, -500}},
       false},
      {FEMALE, "woman-white",
       { ["src"] = "imgs/reina_normal.png",
	  ["reduce"] = 20,
	  ["threshold"] = {0, -500}},
       false}
   }

   local class_members = {{0,0,0}, {0,0,0}, {0,0,0}}

   phq.pj.class_id = 0
   class_members[1][phq.pj.class:to_int() + 1] = 1

   phq.env.school = {}
   local s = phq.env.school
   phq.env.school_day = 0
   s.is_gen = 1
   s.students = {}
   local stds = s.students
   for i = 0, yeLen(npcs) - 1 do
      local npc = yeGet(npcs, i)
      local npc_key = yeGetKeyAt(npcs, i)
      local s_year = yeGet(npc, "student_year")

      if yIsNNil(s_year) then
	 local class = yeGet(npc, "class")
	 yePushBack(stds, npc, npc_key)
	 if (yIsNil(class)) then
	    yeCreateInt(yuiRand() % 3, npc, "class")
	 end
	 class = yeGetInt(class)
	 s_year = yeGetInt(s_year)
	 Entity.wrapp(npc).class_id = class_members[s_year][class + 1]
	 class_members[s_year][class + 1] = class_members[s_year][class + 1] + 1
      end
   end

   for _i = 0, 45 do
      :: again ::
      local gender =  yuiRand() % 2 + 1
      local name_table = array_name[gender]
      local name = rand_array_elem(name_table) .. " " ..
	 rand_array_elem(last_name)
      local year = yuiRand() % 3 + 1
      local class = yuiRand() % 3

      if npcs[name] or class_members[year][class + 1] > 9 then goto again end

      local n = Entity.new_array(npcs, name)
      n.sex = sexes[gender]
      local t = rand_array_elem(types[gender])
      n.type = t
      n.class = class
      n.student_year = year
      yeCreateString("student_ai", n, "ai")
      local hair = Entity.new_array(n, "hair")
      n.max_life = 3 + yuiRand() % 20
      n.is_random_student = 1
      n.reputation = {}
      for _j = 1, year do
	 local rep_rand = yuiRand() % 5

	 if rep_rand == 0 then
	    n.reputation.glandeur = 1 + yuiRand() % 3
	 elseif rep_rand == 1 then
	    n.reputation.slut = 1 + yuiRand() % 3
	 elseif rep_rand == 2 then
	    n.reputation.insane = 1 + yuiRand() % 3
	 elseif rep_rand == 3 then
	    n.reputation.bully = 1 + yuiRand() % 3
	 else
	    n.reputation.weak = 1 + yuiRand() % 3
	 end
      end
      n.stats = {}
      -- charm can be negative...
      n.stats.charm = yuiRand() % 10 * (1 + (yuiRand() % 2 * -2))
      n.stats.strength = yuiRand() % 10
      n.stats.smart = yuiRand() % 10
      n.trait = {}
      n.trait.shy = yuiRand() % 10 * (1 + (yuiRand() % 2 * -2))
      n.trait.violance = yuiRand() % 10 * (1 + (yuiRand() % 2 * -2))
      n.trait.lazy = yuiRand() % 10 * (1 + (yuiRand() % 2 * -2))
      n.trait.grumpy = yuiRand() % 10 * (1 + (yuiRand() % 2 * -2))
      n.trait.sensitivity = yuiRand() % 10 * (1 + (yuiRand() % 2 * -2))
      n.trait.perv = yuiRand() % 10 * (1 + (yuiRand() % 2 * -2))
      -- maybe a male should have less chances to be attrated by male
      -- and same for female ???
      n.trait.male_atraction = yuiRand() % 2 * (1 + (yuiRand() % 2 * -2))
      n.trait.female_atraction = yuiRand() % 2 * (1 + (yuiRand() % 2 * -2))
      n.relation = {}
      n.relation.affection = 0
      n.relation.love = 0
      -- this should be determinate depending of "stats"
      n.attack = "unarmed0"
      hair[0] = rand_array_elem(hair_type[gender])
      hair[1] = rand_array_elem(hair_color)
      yePushBack(stds, n, name)
      -- clothes still needed
      for j = 1, #usable_imgs do
	 uii = usable_imgs[j]
	 if uii[4] == false and uii[1] == gender and
	 uii[2] == t and check_img_cndition(uii[5], n) then
	    uii[4] = true
	    local i_array = Entity.new_array()
	    local threshold = nil
	    if type(uii[3]) == "string" then
	       i_array.src = uii[3]
	    else
	       threshold = uii[3].threshold
	       i_array.src = uii[3].src
	       i_array.reduce = uii[3].reduce
	    end
	    if threshold then
	       ywPosCreate(threshold[1], threshold[2], i_array, "dst-threshold")
	    else
	       ywPosCreate(-100, -300, i_array, "dst-threshold")
	    end
	    n.image = i_array
	    print("give image ", uii[3], "to", name)
	    break
	 end
      end
      local eq = Entity.new_array(n, "equipement")
      eq.torso = rand_array_elem(torso[gender])
      eq.legs = rand_array_elem(legs[gender])
      eq.feet = rand_array_elem(feet[gender])
      dressup.dressUp(n)
      n.class_id = class_members[year][class + 1]
      local school_club
      local school_club_not_good = false
      while school_club_not_good == false do
	 school_club = (yuiRand() % #school_students_organisation) + 1
	 school_club_str = school_students_organisation[school_club]
	 if school_club_str == "Computer club" and gender == FEMALE then
	    school_club_not_good = false
	 else
	    school_club_not_good = true
	 end
      end

      n.knowledge = {}
      n.knowledge.slang = yuiRand() % 5
      n.knowledge.boys_bands = yuiRand() % 4
      n.knowledge.idoles = yuiRand() % 4
      n.knowledge.movies = yuiRand() % 6
      if school_club_str == "Computer club" then
	 n.knowledge.computer = yuiRand() % 8 + 1
	 n.knowledge.animu = yuiRand() % 4
	 n.knowledge.video_game = yuiRand() % 4
      elseif school_club_str == "Mystical Neet Go-under" then
	 n.knowledge.mystical = yuiRand() % 10 + 3
      elseif school_club_str == "Music club" then
	 n.knowledge.boys_bands = yuiRand() % 8
	 n.knowledge.idoles = yuiRand() % 8
	 n.knowledge.guitar = yuiRand() % 8
	 n.knowledge.drum = yuiRand() % 8
	 n.knowledge.music = yuiRand() % 8 + 1
      elseif school_club_str == "Animu Club" then
	 n.knowledge.animu = yuiRand() % 8 + 1
	 n.knowledge.computer = yuiRand() % 4
	 n.knowledge.video_game = yuiRand() % 4
      elseif school_club_str == "Student Club" or
      school_club_str == "Beautification Club" then
	 n.knowledge.fashion = yuiRand() % 6 + 1
	 n.knowledge.makeup = yuiRand() % 6 + 1
      elseif school_club_str == "Students Protection Group" then
	 n.knowledge.weapon = yuiRand() % 6
      elseif school_club_str == "Board Game and Roleplay Club" then
	 n.knowledge.boardgames = yuiRand() % 6 + 1
	 n.knowledge.roleplay = yuiRand() % 6 + 1
      end
      n.organisations = Entity.new_array()
      n.organisations[0] = school_students_organisation[school_club]

      if avaible_house_idx <= #avaible_house then
	 n.house = avaible_house[avaible_house_idx]
	 avaible_house_idx = avaible_house_idx + 1
      end

      class_members[year][class + 1] = class_members[year][class + 1] + 1
   end

   for i = 1, 3 do
      print(class_members[i])
      print(class_members[i][1], class_members[i][2], class_members[i][3])
   end
   construct_students()
end

function end_chapter_1(main)
   print("end_chapter_1")
   main.sleep_script = nil
   phq.env.is_end_of_chapter = 0
   main.gmenu_hook = {}
   phq.env.chapter = 2
   local vn_chapter = Entity.new_array()
   vn_chapter[0] = Entity.new_array()
   local dial = vn_chapter[0]
   dial.text = "End of chapter 1\nchapter 2 TODO: school vacation, lot of 2nddary quest\n" ..
      "to explore side character, and discover new bad guys outsides of school" ..
      "also aligator 427 quest"

   dial.answer = {}
   dial.answer.text = "(goto barly implemented chapter)"
   dial.answer.action = "phq.backToGame"
   phq.quests.school_1_semestre = 2
   phq.quests.school_wvacation = 0

   vnScene(main, nil, vn_chapter)

end

function end_chapter_2(main)
   print("end_chapter_2")
   main.sleep_script = nil
   main.gmenu_hook = {}
   phq.env.is_end_of_chapter = 0
   phq.env.chapter = 3
   phq.quests.school_wvacation = 1
   phq.quests.school_last_semestre = 0
end

function end_chapter_0(main)
   print("end_chapter_0")
   if yIsNil(main.sleep_script) then
      main.sleep_script = "end_chapter_0"
      phq.env.is_end_of_chapter = 1
      return
   end

   print("then ?")
   if phq.env.day:to_int() == 7 and
      phq.env.time:to_string() == "night" then
      phq.env.is_end_of_chapter = 0
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
      phq.pj.class = yuiRand() % 3
      phq.pj.student_year = 1
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
scripts["end_chapter_1"] = end_chapter_1
scripts["end_chapter_2"] = end_chapter_2
scripts["chapter_1"] = chapter_1
scripts["chapter_1_sleep"] = chapter_1_sleep

function rd_tps_ds_escgt()
   if yIsNil(phq.pj.knowledge.history) then
      phq.pj.knowledge.history = 0
   end
   if yIsNil(phq.pj.knowledge.class_struggle) then
      phq.pj.knowledge.class_struggle = 0
   end
   phq.pj.knowledge.history = phq.pj.knowledge.history + 1
   phq.pj.knowledge.class_struggle = phq.pj.knowledge.class_struggle + 1

   ywCntPopLastEntry(main_widget)
   local lteb = Entity.wrapp(ygGet("redwall.story.begin"))
   local lted = Entity.wrapp(ygGet("redwall.story.die"))
   local ltew = Entity.wrapp(ygGet("redwall.story.win"))

   ygModDir("redwall")
   lted.action = Entity.new_func(backToGameDirOut)
   ltew.action = Entity.new_func(backToGameDirOut)
   ywPushNewWidget(main_widget, lteb)
end

function nyanarchist_end(wid)
   wid = Entity.wrapp(wid)
   --yePrint(wid)
   local dwid = ywCntGetEntry(main_widget, -2)
   local dmenu = dialogue_mod.get_menu(dwid)
   if (wid.end_state:to_string() == "win") then
      print("NYANARCHUST BEATEN, PLEAYER NEED REWARD !!!!!")
      dialogue_mod['goto'](dmenu, eve, Entity.new_string("win"))
   else
      print("LOSE BRANCH !")
      dialogue_mod['goto'](dmenu, eve, Entity.new_string("lose"))
   end
   print("ywCntPopLastEntry now")
   ywCntPopLastEntry(main_widget)
end

function croco_start()
   local main = main_widget

   ywCntPopLastEntry(main)
   local t = Entity.new_array()

   t["<type>"] = "croco-427"
   t.pc = phq.pj
   t.quit = Entity.new_func("backToGame2")
   t.die = ygGet("callNextLose")
   --t.die = Entity.new_func("backToGame2")
   t["next-lose"] = main_widget["next-lose"]
   ywPushNewWidget(main, t)
   return YEVE_ACTION
end
