local phq = Entity.wrapp(ygGet("phq"))

local geekDescription = "\"I do undersatdn this \"mouse magic\" that make me thine bidding\"\n" .. "description:\n" ..
   "Like any responsable persones\nyou've spend all your free time watching animu, and playing games\nyou got a lot of knowledges about that\n" ..
   "luckily we live in a computer world"

local idoleDescription = "\"You need a new tailor,  your clothes are absolutely dreadful!\"\n" .. "description:\n" .. "there's 10 kind of boys:\nthe one that love you\nthe gay"

local bruteDescription = "\"So I kicked him in the head 'til he was dead. Mahahahahaha!\"\n" .. "description:\n" ..
   "some peoples are smart, you have muscles\nsome peoples are beautiful you have muscles\nsome peoples think they're strong than you\nYOU BEAT'EM UP\nThe legendary giant's power will tear though the galaxy !"

local wormsCoinoisseurDescription = "\"Surface-dwellers can be so stupid !\"\n" .. "description:\n" ..
   "Most peoples spend they childhoud playing game, thinking about boys or girl, fighting\n" ..
   "You've learn everything you clould about worms, spend a lot of times observing them\n" ..
   "Speaking with your friends about them... your friends are worms\n" ..
   "you gather the kind of knowledge you don't really need in an RPG"

local descArray = {geekDescription, idoleDescription,
		   bruteDescription, wormsCoinoisseurDescription}
GEEK_ARCHETYPE = 0
IDOLE_ARCHETYPE = 1
BRUTE_ARCHETYPE = 2
WORMS_COINOISSEUR_ARCHETYPE = 3

function learn_combot(cmb)
   local cmbs = phq.pj.combots

   cmbs[yeLen(cmbs)] = cmb
end

function newGameAction(menu, eve, arg)
   local game = Entity.wrapp(ygGet("phq:menus.game"))
   game.saved_data = nil
   game.saved_dir = nil
   local archetype = ywMenuGetCurrent(menu)
   phq.quests = {}
   phq.env = File.jsonToEnt("environement.json")
   phq.npcs = File.jsonToEnt("npcs.json")
   phq.pj = {}
   phq.pj.name = "Oscar"
   phq.pj.sex = "female"
   phq.pj.type = "light"
   phq.pj.attack = "unarmed0"
   phq.pj.max_life = 10
   -- reputation is how the other see you, not how you are
   -- if someone give flase rumor about you, it will afect your reputation
   -- if you do something bad, but no one know it, it will afect your trait
   phq.pj.reputation = {}
   phq.pj.reputation.insane = 0
   phq.pj.reputation.bully = 0
   phq.pj.reputation.weak = 0
   -- I don't have polite way for this one, sorry
   phq.pj.reputation.slut = 0
   phq.pj.equipement = {}
   phq.pj.equipement.torso = "white_sleeveless"
   phq.pj.equipement.legs = "teal pants female"
   phq.pj.equipement.feet = "brown_shoes"
   phq.pj.hair = {}
   phq.pj.hair[0] = "shoulderr"
   phq.pj.hair[1] = "blonde"
   phq.pj.inventory = {}
   addObject(nil, phq.pj, "money", 15)
   addObject(nil, phq.pj, "white_sleeveless", 1)
   addObject(nil, phq.pj, "teal pants female", 1)
   addObject(nil, phq.pj, "brown_shoes", 1)
   if archetype == IDOLE_ARCHETYPE then
      addObject(nil, phq.pj, "Pink Guriko", 2)
   else
      addObject(nil, phq.pj, "Guriko", 2)
   end
   phq.pj.stats = {}
   phq.pj.knowledge = {}
   phq.pj.trait = {}
   phq.pj.drunk = 0
   phq.pj.combots = {}
   learn_combot("unarmed0")
   phq.pj.xp = 0
   phq.pj.stats.charm = 0
   phq.pj.stats.strength = 0
   phq.pj.stats.smart = 0
   phq.pj.archetype = archetype
   phq.pj.life = phq.pj.max_life
   phq.pj.allies = {}
   phq.events = {}
   saved_scenes = Entity.new_array()
   if archetype == GEEK_ARCHETYPE then
      phq.pj.knowledge.computer = 5
      phq.pj.knowledge.animu = 5
      phq.pj.stats.smart = 3
      phq.env.mean_name = "losser"
      phq.env.mean_name2 = "nerd"
   elseif archetype == IDOLE_ARCHETYPE then
      phq.pj.knowledge.fashion = 5
      phq.pj.stats.charm = 5
      phq.pj.stats.strength = 1
      addObject(main_widget, phq.pj, "robe_white", 1)
      phq.env.mean_name = "whore"
      phq.env.mean_name2 = "slut"
   elseif archetype == BRUTE_ARCHETYPE then
      phq.pj.knowledge.slang = 5
      phq.pj.trait.violance = 1
      phq.pj.stats.strength = 3
      learn_combot("unarmed1")
      phq.env.mean_name = "dumdass"
      phq.env.mean_name2 = "rat brain"
   elseif archetype == WORMS_COINOISSEUR_ARCHETYPE then
      phq.pj.knowledge.worms = 5
      phq.pj.stats.smart = 1
      phq.env.mean_name = "trash"
      phq.env.mean_name2 = "worthless person"
   end
   yesCall((ygGet("callNext")), menu);
end

function newGameMoveOn(menu, current, cur_entry)
   local tx = ywCntGetEntry(ywCntWidgetFather(menu), 1)
   current = yLovePtrToNumber(current)
   yeSetString(yeGet(tx, "text"), descArray[current + 1])
   return YEVE_NOACTION;
end

function create_new_game(entity)
   local container = Container.init_entity(entity, "vertical")
   entity = Entity.wrapp(entity)
   entity.background = "rgba: 127 127 127 255"
   entity.entries = {}
   entity.entries[0] = {}
   local mn = entity.entries[0]
   mn.size = 20
   mn["<type>"] = "menu"
   mn.next = "phq:menus.game"
   mn.next_target = "main"
   mn.moveOn = Entity.new_func("newGameMoveOn")
   mn.entries = {}
   mn.entries[0] = {}
   mn.entries[0].text = "Geek"
   mn.entries[0].action = Entity.new_func("newGameAction")
   mn.entries[1] = {}
   mn.entries[1].text = "Idole"
   mn.entries[1].action = Entity.new_func("newGameAction")
   mn.entries[2] = {}
   mn.entries[2].text = "Brute"
   mn.entries[2].action = Entity.new_func("newGameAction")
   mn.entries[3] = {}
   mn.entries[3].text = "Worms Conoisseur"
   mn.entries[3].action = Entity.new_func("newGameAction")
   entity.entries[1] = {}
   local txt = entity.entries[1]
   txt["<type>"] = "text-screen"
   txt.text = geekDescription
   local ret = container:new_wid()
   return ret
end
