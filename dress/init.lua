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

--
-- This file is here because PHP scripting I've move some code from sukeban,
-- to this module, and was lazy to port the code to PHP
-- also lua is still faster than PHP
--

dressup = Entity.wrapp(ygGet('dressup'))

objects = nil

function setObjects(path)
   objects = Entity.wrapp(ygGet(path))
   dressup.objects = objects
end

local function getPart(npc, whichpart)
   local e_part = npc[whichpart]
   print(e_part, whichpart)
   if yeType(e_part) == YARRAY then
      yePrint(e_part)
      if yeGetString(e_part[0]) == "rand" then
	 if yIsNil(npc[whichpart .. "rnd"]) then
	    npc[whichpart .. "rnd"] = 1 + (yuiRand() % (yeLen(e_part) - 1))
	 end
	 e_part = e_part[yeGetInt(npc[whichpart .. "rnd"])]
      else
	 e_part = e_part[0]
      end
   end
   print(e_part, whichpart, npc[whichpart .. "rnd"])
   return e_part
end

function dressUp(caracter)
   if yIsNil(objects) then
      explosion("OBJECT MUST BE SET FIRST !!!!")
   end

   caracter = Entity.wrapp(caracter)
   local e = caracter.equipement
   local objs = objects
   local clothes = nil
   caracter.eq_effect = Entity.new_array()

   if caracter.equipement == nil then
      if (yIsNil(caracter.clothes)) then
	 clothes = Entity.new_array(caracter, "clothes")
      else
	 clothes = caracter.clothes
      end
      goto hair;
   end

   caracter.clothes = {}
   clothes = caracter.clothes
   if e.feet then
      local e_feet = getPart(e, "feet")
      local cur_o = objs[yeGetString(e_feet)]

      if (yIsNil(cur_o)) then
	 print("can't find ", yeGetString(e_feet))
      end
      if (cur_o.path) then
	 yeCreateString(cur_o.path:to_string(), clothes)
      end
      if cur_o.equipement_effect then
	 yePushBack(caracter.eq_effect, cur_o.equipement_effect)
      end
      if cur_o.equipement_callback then
	 yesCall(ygGet(yeGetString(cur_o.equipement_callback)));
      end
   end

   if e.legs then
      local e_legs = getPart(e, "legs")
      local cur_o = objs[yeGetString(e_legs)]

      if (yIsNil(cur_o)) then
	 print("can't find ", yeGetString(e_legs))
      end
      if (cur_o.path) then
	 yeCreateString(cur_o.path:to_string(), clothes)
      end
      if cur_o.equipement_effect then
	 yePushBack(caracter.eq_effect, cur_o.equipement_effect)
      end
      if cur_o.equipement_callback then
	 yesCall(ygGet(yeGetString(cur_o.equipement_callback)));
      end
   end

   if e.torso then
      local e_torso = getPart(e, "torso")

      local cur_o = objs[yeGetString(e_torso)]
      if (cur_o.path) then
	 yeCreateString(cur_o.path:to_string(), clothes)
      end
      if cur_o.equipement_effect then
	 yePushBack(caracter.eq_effect, cur_o.equipement_effect)
      end
      if cur_o.equipement_callback then
	 yesCall(ygGet(yeGetString(cur_o.equipement_callback)));
      end
   end

   if e.head then
      local e_head = getPart(e, "head")

      local cur_o = objs[yeGetString(e_head)]
      if (yIsNil(cur_o)) then
	 print("can't find ", yeGetString(e_head))
      end
      if (cur_o.path) then
	 yeCreateString(cur_o.path:to_string(), clothes)
      end
      if cur_o.equipement_effect then
	 yePushBack(caracter.eq_effect, cur_o.equipement_effect)
      end
      if cur_o.equipement_callback then
	 yesCall(ygGet(yeGetString(cur_o.equipement_callback)));
      end
   end

   :: hair ::
   if caracter.hair then
      yeCreateString("hair/" .. caracter.sex:to_string() .. "/" ..
		     caracter.hair[0]:to_string() .. "/" ..
		     caracter.hair[1]:to_string() .. ".png",
		     clothes)
   end
   return nil
end

function dressup_equip(menu)
   menu = Entity.wrapp(menu);
   entry = Entity.wrapp(ywMenuGetCurrentEntry(menu));
   print("Into equit function !!!!!",  entry,
	 menu._ch_)
   menu._ch_.equipement[entry.where:to_string()] = entry[0];
end

function dressup_helpers(mod)
   mod = Entity.wrapp(mod)

   mod.dressUp = Entity.new_func(dressUp)
   mod.setObjects = Entity.new_func(setObjects)
   mod.equip = Entity.new_func(dressup_equip)
   ygRegistreFunc(1, "dressUp", "yDoDressUp")
   return mod
end
