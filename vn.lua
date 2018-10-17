local vn_scenes = ygGet("phq.vn-scenes")

function vnScene(wid, eve, arg, sceneName)
   print("vn scene: ", wid, eve, sceneName, yeGetString(sceneName))
   local main = Entity.wrapp(ywCntWidgetFather(wid))
   local scene = Entity.wrapp(yeGet(vn_scenes, yeGetString(sceneName)))
   print(vn_scenes, scene)
   backToGame(wid)
   local dialogueWid = Entity.new_array()
   dialogueWid["<type>"] = "dialogue"
   dialogueWid.dialogue = scene
   dialogueWid["text-speed"] = 30000
   dialogueWid.background = "rgba: 255 255 255 255"
   ywPushNewWidget(main, dialogueWid)
   return YEVE_ACTION
end