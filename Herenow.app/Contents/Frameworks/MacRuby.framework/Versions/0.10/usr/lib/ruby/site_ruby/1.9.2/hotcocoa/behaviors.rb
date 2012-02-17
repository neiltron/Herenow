##
# A mixin module for classes that subclass Cocoa classes and want to also
# inherit HotCocoa customizations (custom methods, constants, etc.)
module HotCocoa::Behaviors

  ##
  # Implements the callback `Module#included`; this method declares that
  # when `HotCocoa::Behaviors` is mixed in to a class that the class mixing
  # in `HotCocoa::Behaviors` will gain all the HotCocoa customizations made
  # to its superclasses.
  #
  # @example
  #
  #   # Without including, you cannot call HotCocoa custom methods
  #   class CustomView < NSView
  #     def begin
  #       enter_full_screen # => NoMethodError
  #     end
  #   end
  #
  #   # HotCocoa custom methods work when you inculde HotCocoa::Behaviors
  #   class OtherCustomView < NSView
  #     include HotCocoa::Behaviors
  #
  #     def begin
  #       enter_full_screen # => goes full screen
  #     end
  #   end
  #
  def self.included klass
    HotCocoa::Mappings::Mapper.map_class klass
  end

end

##
# Alias for HotCocoa::Behaviors
#
# @return [Module]
HotCocoa::Behaviours = HotCocoa::Behaviors
