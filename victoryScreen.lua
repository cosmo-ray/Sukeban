
function victoryScreenAction(vs, eve)
   eve = Event.wrapp(eve)

   while eve:is_end() == false do
      print("loop")
      if eve:type() == YKEY_DOWN then
	 if eve:key() == Y_ENTER_KEY then
	    print("enter")
	    backToGame(vs)
	    return YEVE_ACTION
	 end
      end
      eve = eve:next()
   end
   return YEVE_NOTHANDLE
end

function puushNewVictoryScreen(main)
   local victoryScreen = Entity.new_array()

   victoryScreen["<type>"] = "text-screen"
   victoryScreen["text-align"] = "center"
   victoryScreen.text = "tatatata ta ta ta tata"
   victoryScreen.background = "rgba: 155 155 255 190"
   victoryScreen.action = Entity.new_func("victoryScreenAction")
   ywPushNewWidget(main, victoryScreen)
end
