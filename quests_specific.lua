local phq = Entity.wrapp(ygGet("phq"))
local drunk_txt = nil
local drunk_bar0 = nil
local drunk_bar1 = nil
local window_width = 800
local window_height = 600

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
end

scripts = {}
scripts["inter_bar_in"] = inter_bar_in
scripts["inter_bar_out"] = inter_bar_out
scripts["inter_bar_running"] = inter_bar_running

