local phq = Entity.wrapp(ygGet("phq"))

local geekDescription = "I do undersatdn this 'mouse magic'\nthat make me do binding"
local idoleDescription = "Erk, You need a new tailor"
local bruteDescription = "I CRUSH YOU! ME CRUSH YOU TO GOO!"
local wormsCoinoisseurDescription = "I hate surface dweller !"
local descArray = {geekDescription, idoleDescription,
		   bruteDescription, wormsCoinoisseurDescription}

function newGameAction(menu, eve, arg)
   local game = Entity.wrapp(ygGet("phq:menus.game"))
   game.saved_data = nil
   game.saved_dir = nil
   phq.pj.drunk = 0
   phq.pj.life = phq.pj.max_life
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
   mn.size = 30
   mn["<type>"] = "menu"
   mn.next = "phq:menus.game"
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
