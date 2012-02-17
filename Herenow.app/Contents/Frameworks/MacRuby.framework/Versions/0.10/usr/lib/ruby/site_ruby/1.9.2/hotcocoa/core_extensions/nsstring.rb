##
# HotCocoa extensions for the NSString class.
class NSString

  ##
  # Borrowed from Active Support.
  def underscore
    new_string = gsub /::/, '/'
    new_string.gsub! /([A-Z]+)([A-Z][a-z])/, '\1_\2'
    new_string.gsub! /([a-z\d])([A-Z])/, '\1_\2'
    new_string.tr! '-', '_'
    new_string.downcase!
    new_string
  end

  ##
  # Borrowed from Active Support.
  def camel_case
    gsub /(?:^|_)(.)/ do $1.upcase end
  end

  ##
  # Create an attributed string with the given attributes. The list of
  # applicable attributes can be found in the Apple documentation for
  # NSAttributedString class, as well as the ATTRIBUTE_KEYS hash in the
  # {HotCocoa::NSRangedProxyAttributeHash} class.
  #
  # @param [Hash] attributes
  # @return [NSMutableAttributedString]
  def with_attributes attributes = {}
    attributed_string = NSMutableAttributedString.alloc.initWithString self
    attributed_string.attributes << attributes
    attributed_string
  end

end
