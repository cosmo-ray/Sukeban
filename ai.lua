local ACTION_MOVE = 1

function NpcTurn(wid)
   local i = 0
   local npc_act = wid.npc_act
   while i < yeLen(npc_act) do
      print("hi", wid.npc_act[i])
      i = i + 1
   end
end

function PjLeaveController(wid, action)
   printf("PjLeaveController", wid, action)
end

function PjLeave(owid, eve, arg, entryPoint)
   wid = Entity.wrapp(yDialogueGetMain(owid))
   local main = Entity.wrapp(ywCntWidgetFather(wid))
   local npc = main.npcs[wid.npc_nb:to_int()]
   local action = Entity.new_array(main.npc_act)
   --action.npc = npc
   action.type = ACTION_MOVE
   action.up_down = 0
   action.left_right = 0
   action.controller = Entity.new_func("PjLeaveController")
   EndDialog(owid, eve, arg)
end
