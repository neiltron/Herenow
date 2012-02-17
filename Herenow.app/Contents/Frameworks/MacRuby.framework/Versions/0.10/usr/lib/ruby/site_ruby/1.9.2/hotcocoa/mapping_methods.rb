# -*- coding: utf-8 -*-

##
# The set of methods that are available when creating a mapping.
module HotCocoa::MappingMethods

  ##
  # You can provide a hash of default options in the definition of
  # your mapping. This is very useful for many Cocoa classes, because
  # there are so many options to set at initialization.
  #
  # Details about how defaults are used can be found in the
  # {file:docs/Mappings.markdown Mappings} tutorial.
  #
  # @overload defaults
  #   Get the hash of defaults
  #   @return [Hash,nil]
  #
  # @overload defaults key1: value1, key2: value2, ...
  #   Set the hash of defaults
  #   @param [Hash]
  #   @return [Hash]
  def defaults defaults = nil
    if defaults
      @defaults = defaults
    else
      @defaults
    end
  end

  ##
  # Create a mapping of a constant type to an enumeration of constants.
  #
  # A constant mapping allows the use of short symbol names to be used
  # in place of long constant names in the scope of the wrapped class.
  #
  # Details about using this method are in the
  # {file:docs/Mappings.markdown} tutorial.
  #
  # @param [Symbol] name
  # @param [Hash{Symbol=>Constant}] constants
  def constant name, constants
    constants_map[name] = constants
  end

  ##
  # A mapping of constant mappings that were created with calls to
  # {#constant}
  #
  # @return [Hash{Symbol=>Hash{Symbol=>Constant}}]
  attr_reader :constants_map

  ##
  # Custom methods are modules that are mixed into the class being
  # mapped; they provide idiomatic Ruby methods for the mapped
  # Objective-C class instances.
  #
  # Custom methods are meant to be used in conjunction with constant
  # mappings or when the custom method provides something much better
  # than what is offered by plain Cocoa. Examples are available in the
  # {file:docs/Mappings.markdown} tutorial.
  #
  # @yield A block that will be evaluated in the context of a new module
  #
  # @overload custom_methods do ... end
  #   Create and cache a new module to mix into the mapped class
  #   @return [Module] return the module that caches the custom methods
  #
  # @overload custom_methods
  #   @return [Module,nil] return the Module if it exists, otherwise nil
  def custom_methods &block
    if block
      @custom_methods = Module.new &block
    else
      @custom_methods
    end
  end

  ##
  # Delegation is a pattern that is used pervasively in Cocoa to
  # facilitate customization of controls; it is a powerful tool, but
  # is a little more complex to setup than custom methods.
  #
  # You should read the {file:docs/Mappings.markdown Mappings} tutorial
  # to get an in depth understanding on how to setup delegates in
  # HotCocoa.
  #
  # @param [String,Symbol] name
  # @param [Hash{:to=>:ruby_name, :parameters=>Array<String>}] options
  #   the `:to` key must be included, but `:parameters` is optional
  def delegating name, options
    delegate_map[name] = options
  end

  ##
  # A mapping of delegate mappings that were created with calls to
  # {#delegating}
  #
  # @return [Hash{Symbol=>Hash{Symbol=>SEL}}]
  attr_reader :delegate_map

  ##
  # A small hack so that we can have {#delegate_map} and {#constants} as
  # attributes instead of methods that memoize instance variables.
  def self.extended klass
    klass.instance_variable_set :@constants_map, {}
    klass.instance_variable_set :@delegate_map,  {}
  end

end
