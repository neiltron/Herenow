##
# HotCocoa extensions to the NSMutableAttributeString class.
class NSMutableAttributedString

  ##
  # @todo Should this be declared on NSAttributedString instead
  #
  # Make a new attributed string with the string of the receiver and
  # the attributes passed as arguments.
  #
  # @param [Hash]
  # @return [NSMutableAttributedString]
  def with_attributes attributes = {}
    string.with_attributes attributes
  end

  ##
  # Just like `String#<<`
  def << s
    case s
    when String
      mutableString.appendString s
    else
      appendAttributedString s
    end
  end

  ##
  # @todo Should this be declared on NSAttributedString instead
  #
  # Just like `String#+`
  def + s
    attributed_string = mutableCopy
    attributed_string << s
    attributed_string
  end

  ##
  # @todo Should this be declared on NSAttributedString instead
  #
  # Hash of attributes used in the attributed string.
  #
  # @return [HotCocoa::NSRangedProxyAttributeHash]
  def attributes
    HotCocoa::NSRangedProxyAttributedString.new(self, 0..-1).attributes
  end

  ##
  # @deprecated Who uses this? Removing this in HotCocoa 0.7 unless
  #   there are reasonable objections
  #
  # Create a range proxy for an arbitrary portion of the receiver.
  #
  # @param [Range] r
  # @return [HotCocoa::NSRangedProxyAttributedString]
  def [] r
    HotCocoa::NSRangedProxyAttributedString.new self, r
  end

  ##
  # Replace an arbitrary range of an attributed string with another string.
  #
  # @param [Range] r
  # @param [NSAttributedString,String] s
  def []= r, s
    case s
    when String
      replaceCharactersInRange r.to_NSRange(length), withString: s
    else
      replaceCharactersInRange r.to_NSRange(length), withAttributedString: s
    end
  end

end
