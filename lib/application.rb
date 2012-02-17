require 'rubygems' # disable this for a deployed application
require 'hotcocoa'
require 'pp'

framework 'appkit'
framework 'IOBluetooth'


class Herenow
  include HotCocoa

  def start
    @app = application :name => 'Herenow', :delegate => self
    @status = status_item
    
    @current = 'Search'
    @devices = []
    
    setup_menu
    
    @inquiry = IOBluetoothDeviceInquiry.new
    @inquiry.setUpdateNewDeviceNames(true)
    @inquiry.setDelegate(self)
    @inquiry.start
    
    @app.run
  end
  
  def setup_menu
    @menu = status_menu
    @status.view = nil
    @status.menu = @menu
    @status.image = image :file => "#{lib_path}/../resources/levitate.png", :size => [ 17, 17 ]
    @status.setHighlightMode true
  end
  
  def status_menu
    menu :delegate => self do |status|
      status.item @current, :on_action => proc { @inquiry.start }
      status.separator unless @devices.empty?
      @devices.each do |device|
        status.item device
      end
      status.separator
      status.item "Quit", :on_action => proc { @app.terminate self }
    end
  end

  def set_status (status)
    @current = status
    
    setup_menu
  end
  
  def start_scan
    @inquiry.start
  end
  
  def lib_path
    File.dirname __FILE__
  end
  
  def deviceInquiryStarted(sender)
    @devices = []
    set_status('Searching...')
  end

  def deviceInquiryComplete(sender, error:error, aborted:aborted)
    if !@devices.include?('realtron')
      pid = `echo $(ps -e | grep '[i]Chat' | awk '{print $1}')`.strip

      unless pid.empty?
        `kill #{pid}`
      end
    end
      
    set_status('Search')
    
    NSTimer.scheduledTimerWithTimeInterval 10,
          target:self, 
          selector:'start_scan', 
          userInfo:nil, 
          repeats:false
  end

  def deviceInquiryDeviceFound(sender, device:device)
    @devices.push device.nameOrAddress.downcase
    setup_menu
    
    if device.nameOrAddress.downcase == 'realtron'
      open = `/usr/bin/open /Applications/iChat.app`
    end
  end

  def deviceInquiryDeviceNameUpdated(sender, device:device, devicesRemaining:remaining)
    puts "Update name of device #{device}: '#{device.nameOrAddress}'"
  end

  def deviceInquiryUpdatingDeviceNamesStarted(sender, devicesRemaining:remaining)
    puts "Updating names of: #{remaining}"
    sender.stop if remaining == 0
  end
end

Herenow.new.start
