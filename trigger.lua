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

function trigger_block_message(wid, trigger, msg)
   local t = Entity.wrapp(trigger)
   if yIsNil(t.print_timer) or
      os.time() - yeGetInt(t.print_timer) > 2 then
      t.print_timer = os.time()
      printMessage(main_widget, nil, msg)
   end
   t.colision_ret = NORMAL_COLISION
   t.no_disable_timer = true
end
