require 'Win32API'

module DelcomDLL
  DEBUG = false

  DelcomGetDeviceCount = Win32API.new("DelcomDLL", "DelcomGetDeviceCount", %w(l), 'l')
  def self.getDeviceCount(type)
    return DelcomGetDeviceCount.Call(type)
  end

  DelcomGetNthDevice = Win32API.new("DelcomDLL", "DelcomGetNthDevice", %w(l l p), 'l')
  def self.getNthDevice(type, nth)
    deviceName = ' ' * 512
    DelcomGetNthDevice.Call(type, nth, deviceName) != 0 or raise "getNthDevice(#{type}, #{nth}) failed"
    return deviceName.clone.gsub(/\0+$/, "")
  end
  
  DelcomOpenDevice = Win32API.new("DelcomDLL", "DelcomOpenDevice", %w(p l), 'l')
  def self.openDevice(name)
    result = DelcomOpenDevice.Call(name, 0)
    result != 0 or raise "openDevice(#{name}) failed"
    result
  end

  DelcomCloseDevice = Win32API.new("DelcomDLL", "DelcomCloseDevice", %w(l), 'l')
  def self.closeDevice(handle)
    result = DelcomCloseDevice.Call(handle)
    result == 0 or raise "closeDevice(#{handle}) failed: #{result}"
  end
  
  DelcomBuzzer = Win32API.new("DelcomDLL", "DelcomBuzzer", %(l n n n n n), 'l')
  def self.delcomBuzzer(handle, mode, freq, repeat, onTime, offTime)
    result = DelcomBuzzer.Call(handle, mode, freq, repeat, onTime, offTime)
    result == 0 or raise "delcomBuzzer(#{handle}) failed: #{result}"
  end
  
  DelcomSendPacket = Win32API.new("DelcomDLL", "DelcomSendPacket", %w(l p p), 'l')
  def self.sendPacket(handle, properties)
    default_properties = { 
      :Recipient => 8, :DeviceModel => 18, 
      :MajorCmd => 0, :MinorCmd => 0,
      :DataLSB => 0, :DataMSB => 0,
      :ExtData => []
    }
    properties = default_properties.merge(properties)
    properties[:Length] = 8 + properties[:ExtData].length
    puts properties.inspect if DEBUG

    fields = [ :Recipient, :DeviceModel, :MajorCmd, :MinorCmd, :DataLSB, :DataMSB, :Length, :ExtData ]
    values = fields.collect { |field| properties[field] or raise "Missing property #{field}" }.flatten
    puts values.inspect if DEBUG
    bytes = values.pack("C6sc*")
    
    output = ([0] * 16).pack("c*")
    
    result = DelcomSendPacket.Call(handle, bytes, output)
    result == 0 or raise "Failed: sendPacket(#{properties.inspect}): #{result}"
    output.unpack("c*")
  end
  
  DelcomVerboseControl = Win32API.new("DelcomDLL", "DelcomVerboseControl", %w(l p), 'l')
  def self.verboseControl(mode, header)
    DelcomVerboseControl.Call(mode, header)
  end

  def self.checkResult(result, function)
    raise "#{function} returned #{result}" unless result == 0
  end
  
  USBIODS = 1
  USBIODELVI = 2
  USBNDSPY = 3
  
  GREENLED = 0
  REDLED = 1
  BLUELED = 2
  
  GREEN = 1
  RED = 2
  BLUE = 4
  
end
