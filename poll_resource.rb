require './visual_indicator'
require 'open-uri'

# Usage
#  poll_resource <url> [<led number>] [<polling frequency>]
#    url: a file or http url that should be polled every five seconds
#    led number: 0...x where x is the number of LEDs connected to this computer
#    polling frequency: The number of seconds between checking the URL

led = VisualIndicator.all[ARGV[1] || 0]

while true
  begin
    open(ARGV[0]) { |f| led.parse_command(f) }
  rescue => e
    puts "Could not access #{ARGV[0]}: #{e.message}"
    led.all.off
    led.red.flash 10, 10
  end
  sleep (ARGV[2] || "5").to_i
end