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
