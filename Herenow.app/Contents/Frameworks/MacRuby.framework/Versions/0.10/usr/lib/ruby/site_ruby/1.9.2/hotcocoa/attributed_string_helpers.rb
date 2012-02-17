##
# Similar to a Ruby Hash, except specialized for dealing with a hash
# of attributes for NSAttributedString objects.
class HotCocoa::NSRangedProxyAttributeHash

  # @return [Hash{Symbol=>StandardAttributedStringAttributes}]
  ATTRIBUTE_KEYS = {
    font:                  NSFontAttributeName,
    paragraph_style:       NSParagraphStyleAttributeName,
    color:                 NSForegroundColorAttributeName,
    colour:                NSForegroundColorAttributeName,
    underline_style:       NSUnderlineStyleAttributeName,
    superscript:           NSSuperscriptAttributeName,
    background_color:      NSBackgroundColorAttributeName,
    background_colour:     NSBackgroundColorAttributeName,
    attachment:            NSAttachmentAttributeName,
    ligature:              NSLigatureAttributeName,
    baseline_offset:       NSBaselineOffsetAttributeName,
    kerning:               NSKernAttributeName,
    link:                  NSLinkAttributeName,
    stroke_width:          NSStrokeWidthAttributeName,
    stroke_color:          NSStrokeColorAttributeName,
    underline_color:       NSUnderlineColorAttributeName,
    strikethrough_style:   NSStrikethroughStyleAttributeName,
    strikethrough_color:   NSStrikethroughColorAttributeName,
    strikethrough_colour:  NSStrikethroughColorAttributeName,
    shadow:                NSShadowAttributeName,
    obliqueness:           NSObliquenessAttributeName,
    expansion_factor:      NSExpansionAttributeName,
    cursor:                NSCursorAttributeName,
    tool_tip:              NSToolTipAttributeName,
    character_shape:       NSCharacterShapeAttributeName,
    glyph_info:            NSGlyphInfoAttributeName,
    marked_clause_segment: NSMarkedClauseSegmentAttributeName,
    spelling_state:        NSSpellingStateAttributeName
  }

  # @param [HotCocoa::NSRangedProxyAttributedString]
  def initialize proxy
    @proxy = proxy
  end

  def [] k
    k = attribute_for_key k
    @proxy.string.attribute k, atIndex: @proxy.range.first, effectiveRange: nil
  end

  def []= k, v
    k = attribute_for_key k
    @proxy.string.removeAttribute k,
                           range: @proxy.range.to_NSRange(@proxy.string.length)
    @proxy.string.addAttribute k,
                        value: v,
                        range: @proxy.range.to_NSRange(@proxy.string.length)
  end

  ##
  # Append new attributes to the string
  #
  # @param [Hash] attributes
  def << attributes
    attributes.each_pair { |k, v| self[k] = v }
    self
  end
  alias_method :merge!, :<<

  ##
  # Return a hash of the attributes, but without transforming constant
  # names.
  #
  # @return [NSMutableDictionary]
  def to_hash
    dict = @proxy.string.attributesAtIndex @proxy.range.first,
                           effectiveRange: nil
    NSMutableDictionary.dictionaryWithDictionary dict
  end

  # @return [String]
  def inspect
    to_hash.inspect
  end


  private

  def key_for_attribute attribute
    ATTRIBUTE_KEYS.key(attribute) || attribute
  end

  def attribute_for_key key
    ATTRIBUTE_KEYS[key] || key
  end
end


##
# Proxies the range of an attributed string.
class HotCocoa::NSRangedProxyAttributedString

  ##
  # The string this proxy belongs to.
  #
  # @return [NSMutableAttributedString]
  attr_reader :string

  ##
  # Range in the string this proxy represents.
  #
  # @return [Range]
  attr_reader :range

  # @param [NSMutableAttributedString] string
  # @param [Range] range
  def initialize string, range
    @string = string
    @range  = range
  end

  ##
  # This method is useful because it allows an attributed string to
  # return a hash of attributes that use Rubyish names instead of
  # Objective-C ones.
  #
  # @return [HotCooca::NSRangedProxyAttributeHash]
  def attributes
    HotCocoa::NSRangedProxyAttributeHash.new self
  end
end
