require 'stringio'
require 'visual_indicator'

VisualIndicator.all.each { |lamp| lamp.parse_command StringIO.new("all off") }
