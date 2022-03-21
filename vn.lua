local vn_scenes = ygGet("phq.vn-scenes")

function vnScene(wid, eve, scene, dialogueWid)
   wid = Entity.wrapp(wid)
   if wid.isDialogue then
      wid = main_widget
   end

   if yeGetInt(wid.in_subcontained) == 1 then
      wid = Entity.wrapp(ywCntWidgetFather(wid))
   end
   local main = Entity.wrapp(main_widget)

   if yeType(scene) == YSTRING then
      scene = Entity.wrapp(yeGet(vn_scenes, yeGetString(scene)))
   end
   backToGame(wid)
   if yIsNil(dialogueWid) then
      dialogueWid = Entity.new_array()
   end
   dialogueWid["<type>"] = "dialogue"
   dialogueWid.dialogue = scene
   dialogueWid["text-speed"] = 30000
   dialogueWid.background = "rgba: 255 255 255 255"
   dialogueWid.endAction = Entity.new_func("backToGame")
   ywPushNewWidget(main, dialogueWid)
   return YEVE_ACTION
end
