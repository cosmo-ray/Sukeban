local vn_scenes = ygGet("phq.vn-scenes")

function vnScene(wid, eve, scene)
   wid = Entity.wrapp(wid)
   if yeGetInt(wid.in_subcontained) == 1 then
      wid = Entity.wrapp(ywCntWidgetFather(wid))
   end
   local main = Entity.wrapp(main_widget)

   if yeType(scene) == YSTRING then
      scene = Entity.wrapp(yeGet(vn_scenes, yeGetString(scene)))
   end
   backToGame(wid)
   local dialogueWid = Entity.new_array()
   dialogueWid["<type>"] = "dialogue"
   dialogueWid.dialogue = scene
   dialogueWid["text-speed"] = 30000
   dialogueWid.background = "rgba: 255 255 255 255"
   dialogueWid.endAction = Entity.new_func("backToGame")
   ywPushNewWidget(main, dialogueWid)
   return YEVE_ACTION
end
