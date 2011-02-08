require 'stringio'
require 'visual_indicator'

VisualIndicator.first.parse_command StringIO.new("""
    red on 30
    green off
    yellow flash 20 40 10
  """)

VisualIndicator.last.parse_command StringIO.new("""
    red on
    green flash 40 40
    yellow flash
  """)
