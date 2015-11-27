require 'visual_indicator'
require 'open-uri'
require 'rexml/document'

# Usage
#  poll_resource [<jenkins-url>|http://localhost:8080/job/foo] [<led number>] [<polling frequency>]
#    url: a file or http url that should be polled every five seconds
#    led number: 0...x where x is the number of LEDs connected to this computer
#    polling frequency: The number of seconds between checking the URL

$led = VisualIndicator.all[ARGV[1] || 0]
status_url = "#{ARGV[0] || 'http://localhost:8080/job/foo'}/api/xml"

END {
  $led.all.off
}

Status = Struct.new(:led_color, :is_building, :is_error, :was_aborted)

$new_status = $status = Status.new("green", false, false)

def update_status(step)
  if $status != $new_status
    puts $new_status
    $status = $new_status
    $led.all.off
    if $status.is_error
      $led.red.flash 10, 10, 100
    else
      $led.yellow.on 100 if $status.was_aborted
      $led[$status.led_color].on $status.is_building ? step : 80
    end
  elsif $status.is_building
    $led[$status.led_color].on step
  end
end

Thread.new do
  steps = [5,7,8,10,20,30,40,50,60,70,80,90,100]
  steps += steps.reverse
  while true
    begin
      steps.each { |step| update_status(step); sleep 0.1 }
    rescue => e
      puts e
	end
  end
end


LED_COLOR = {
	"blue" => "green", "blue_anime" => "green", 
	"yellow" => "yellow", "yellow_anime" => "yellow",
	"red" => "red", "red_anime" => "red",
	"aborted" => "green", "aborted_anime" => "green",
}

while true
  begin
    open(status_url) do |f|
      doc = REXML::Document.new(f)
      color = doc.elements["mavenModuleSet/color"].text
	  $new_status = Status.new(
		LED_COLOR[color],
		color =~ /_anime$/, 		
		!LED_COLOR.key?(color),
		color =~ /^aborted/)
    end
  rescue => e
    puts "Could not access #{ARGV[0]}: #{e.message}"
    $new_status = Status.new("red", false, true, false)
  end
  sleep (ARGV[2] || "5").to_i
end
