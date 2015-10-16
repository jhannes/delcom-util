require './delcom-dll'


class VisualIndicator
  GREENLED = 0
  REDLED = 1
  BLUELED = 2
  
  GREEN = 1
  RED = 2
  BLUE = 4

  class Led
    def initialize(visualIndicator, light, light_offset)
      @visualIndicator = visualIndicator
      @light = light
      @light_offset = light_offset
      [1, 2, 4].include? light or raise "Illegal light #{light}"
      [0, 1, 2].include? light_offset or raise "Illegal light_offset #{light_offset}"
    end
    
    def execute(args)
      case args[0].downcase
        when "flash" then flash(args[1] && args[1].to_i, args[2] && args[2].to_i, args[3] && args[3].to_i)
        when "on" then on(args[1] && args[1].to_i)
        when "off" then off
      end
    end
    
    def off
      write_command(20,  :DataLSB => @light)
      write_command(12,  :DataMSB => @light)
    end
    
    def on(power = nil)
      set_power(power) if power
      write_command(20,  :DataLSB => @light)
      write_command(12,  :DataLSB => @light)
    end
    
    def flash(offDuty = nil, onDuty = nil, power = nil)
      set_duty_cycle(offDuty, onDuty) if offDuty && onDuty
      set_power(power) if power
      write_command(20,  :DataMSB => @light)
      write_command(12,  :DataLSB => @light)
    end
    
    def set_duty_cycle(offDuty, onDuty)
      write_command(21 + @light_offset,  
        :DataLSB => validate(offDuty, 0..255), :DataMSB => validate(onDuty, 0..255))
    end
    
    def set_offset(offset)
      write_command(27 + @light_offset,  :DataLSB => validate(offset, 0..255))      
    end
    
    def set_power(power)
      write_command(34, :DataLSB => @light_offset, :DataMSB => validate(power, 0..100))      
    end
    
    
    def validate(value, range)
      range.include? value or raise "#{value} outside range #{range}"
      value
    end
    
    def write_command(command, properties)
      @visualIndicator.write_command(command, properties)
    end    
  end
  
  class All
    def initialize(visualIndicator, leds)
      @visualIndicator = visualIndicator
      @leds = leds
    end
    
    def on(power = nil)
      @leds.each { |l| l.on(power) }
    end
    def flash(offDuty = 20, onDuty = 20, power = nil)
      @visualIndicator.sync_leds(RED|GREEN|BLUE)
      @leds.each { |l| l.flash(offDuty, onDuty, power) }
    end
    def off
      @leds.each { |l| l.off }
    end
    def execute(args)
      @leds.each { |l| l.off }
    end
  end
  
  def initialize(deviceName)
    @deviceName = deviceName
  end

  def self.all
    deviceCount = DelcomDLL::getDeviceCount(DelcomDLL::USBIODELVI)
    (0...deviceCount).collect { |index| self.new(DelcomDLL::getNthDevice(DelcomDLL::USBIODELVI, index)) }
  end
  
  def self.first; all.first; end
  def self.last; all.last; end
  
  def red; Led.new(self, RED, REDLED); end
  def green; Led.new(self, GREEN, GREENLED); end
  def yellow; Led.new(self, BLUE, BLUELED); end
  def blue; Led.new(self, BLUE, BLUELED); end
  def all; All.new(self, [red, green, yellow]); end
  
  def parse_command(indicators_as_string)
    all.off
    indicators_as_string.each_line do
      |line|
      command = line.strip.split
      self[command[0]].execute(command[1..-1]) if command[0]
    end  
  end
  
  def [](color)
    case color.downcase
      when "red" then red
      when "green" then green
      when "blue" then blue
      when "yellow" then yellow
      when "all" then all
    end
  end
  
  def serial_number
    firmware_info = read_firmware_info
    firmware_info[0..3].pack("c*").unpack("V")
  end
  
  def firmware_version
    read_firmware_info[4]
  end
  
  def firmware_date
    firmware_info = read_firmware_info
    Date.new(2000+firmware_info[7] , firmware_info[6], firmware_info[5])
  end
  
  def read_firmware_info
    read_command(10)
  end
  
  def read_switch_counter
    read_command(8)[0]
  end
  
    
  def sync_leds(in_on_state, in_off_state=0)
    write_command(25, :DataMSB => in_off_state, :DataLSB => in_on_state)
  end

  def start_buzzer(frequency, repeat, onTime, offTime)
    handle = @handle || DelcomDLL::openDevice(@deviceName)
    output = DelcomDLL::delcomBuzzer(handle, 1, frequency, repeat, onTime, offTime)
    DelcomDLL::closeDevice(handle) unless @handle
    output
  end
  
  def stop_buzzer
    handle = @handle || DelcomDLL::openDevice(@deviceName)
    output = DelcomDLL::delcomBuzzer(handle, 0, 0, 0, 0, 0)
    DelcomDLL::closeDevice(handle) unless @handle
    output
  end
  
  def write_command(command, properties = {})
    properties[:MajorCmd] ||= 10
    properties[:MinorCmd] ||= command
    handle = @handle || DelcomDLL::openDevice(@deviceName)
    output = DelcomDLL.sendPacket(handle, properties)
    DelcomDLL::closeDevice(handle) unless @handle
    output
  end

  def read_command(command)
    write_command(command, :MajorCmd => 11)
  end
  
  def open_device
    @handle = DelcomDLL::openDevice(@deviceName)
  end
  
  def close_device
    DelcomDLL::closeDevice(@handle)
    @handle = nil
  end
end


