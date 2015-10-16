require './visual_indicator'

for lamp in VisualIndicator.all
  lamp.open_device
  lamp.start_buzzer(2, 2, 6, 2)
  lamp.stop_buzzer

  lamp.red.flash
  lamp.red.on(10)
  lamp.red.off

  lamp.blue.flash(10, 10)
  lamp.blue.on
  lamp.blue.off

  lamp.green.flash(10, 10, 100)
  lamp.green.on
  lamp.green.off
  
  lamp.close_device
end
