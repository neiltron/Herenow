module HotCocoa::Mappings
  # needs to be initialized
  @mappings = {}

  ##
  # This is a hack to work around a MacRuby issue with compiled files.
  #
  # Return the absolute path to `lib/hotcocoa`.
  #
  # @return [String]
  file = $LOADED_FEATURES.find { |file| file.match /hotcocoa\/mappings\.rbo?$/ }
  @path = File.expand_path(File.join(File.dirname(file), 'mappings'))
end

class << HotCocoa::Mappings

  ##
  # The cache of mappers for available mappings.
  #
  # @return [Hash{Symbol=>HotCocoa::Mappings::Mapper}]
  attr_reader :mappings

  ##
  # Load mappings for every loaded framework.
  def reload
    $LOADED_FRAMEWORKS.each do |framework| load framework end
  end

  ##
  # Load mappings for a given framework.
  #
  # @param [String] framework
  def load framework
    framework = framework.downcase
    dir       = File.join(@path, framework)
    if Dir.exists? dir
      Dir.glob(File.join(dir, '**/*.rb')).each do |mapping|
        require mapping.chomp! '.rb'
      end
    end
  end

  ##
  # Create a new mapping by registering `mapped_name` as a builder
  # method for `mapped_class`.
  #
  # @example
  #
  #   HotCocoa::Mappings.map( window: NSWindow ) do
  #     # define your mapping
  #   end
  #
  # @param [Symbol] mapped_name
  # @param [Class]  mapped_class
  def map name, &block
    mapped_name, mapped_class = name.first
    mappings[mapped_name] =
      HotCocoa::Mappings::Mapper.map_instances_of mapped_class, mapped_name, &block
  end

end
