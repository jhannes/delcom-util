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

$status = :none

def status(new_status)
  return if new_status == $status
  $status = new_status
  case $status
    when :ok then $led.all.off; $led.green.on 100
    when :build_from_ok then $led.all.off; $led.green.flash 50,50,100
    when :fail then $led.all.off; $led.yellow.on 100
    when :build_from_fail then $led.all.off; $led.yellow.flash 50,50,100
    when :error then $led.all.off; $led.red.on 100
    when :build_from_error then $led.all.off; $led.red.flash 50,50,100
    when :system_error then $led.all.off; $led.red.flash 10, 10, 100
    else $led.all.off; $led.red.flash 5, 5, 100
  end
end


while true
  begin
    open(status_url) do |f|
      doc = REXML::Document.new(f)
      color = doc.elements["mavenModuleSet/color"].text
      puts color
      case color
        when "blue" then status(:ok)
        when "blue_anime" then status(:build_from_ok)
        when "yellow" then status(:fail)
        when "yellow_anime" then status(:build_from_fail)
        when "red" then status(:error)
        when "red_anime" then status(:build_from_error)
        else status(:unknown)
      end
    end
  rescue => e
    puts "Could not access #{ARGV[0]}: #{e.message}"
    status(:system_error)
  end
  sleep (ARGV[2] || "1").to_i
end