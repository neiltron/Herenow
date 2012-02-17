##
# HotCocoa extensions for the Kernel module
module Kernel

  ##
  # Like $LOADED_FEATURES, but for frameworks.
  #
  # @return [Array<String>]
  $LOADED_FRAMEWORKS = []

  alias_method :default_framework, :framework
  ##
  # Override MacRuby's built-in #framework method in order to support lazy
  # loading frameworks inside of HotCocoa.
  def framework name
    if default_framework name
      $LOADED_FRAMEWORKS << name
      HotCocoa::Mappings.load name
      true
    else
      false
    end
  end

  # Populate the list with everything that has already been loaded
  $LOADED_FRAMEWORKS.concat NSBundle.allFrameworks.map { |bundle|
    bundle.bundlePath.split('/').last
  }.select { |framework|
    framework.split('.')[1] == 'framework'
  }.map! { |framework|
    framework.split('.')[0]
  }
  $LOADED_FRAMEWORKS.uniq!

  ##
  # A mapping, lol
  #
  # @return [Hash]
  PLIST_FORMATS = {
    xml:    NSPropertyListXMLFormat_v1_0,
    binary: NSPropertyListBinaryFormat_v1_0
  }

  ##
  # @todo encoding format can be pushed upstream?
  #
  # Override MacRuby's built-in {Kernel#to_plist} method to support
  # specifying an output format. See {PLIST_FORMATS} for the available
  # formats.
  #
  # @example Encoding a plist in the binary format
  #   { key: 'value' }.to_plist(:binary)
  #
  # @return [String] returns a string with the caller's contents
  #   serialized as a plist and encoded using `format`
  def to_plist format = :xml
    format_const = PLIST_FORMATS[format]
    raise ArgumentError, "invalid format `#{format}'" unless format_const

    error = Pointer.new :id
    data  = NSPropertyListSerialization.dataFromPropertyList self,
                                                     format: format_const,
                                           errorDescription: error
    error[0] ? raise(Exception, error[0]) : data.to_str
  end

end
