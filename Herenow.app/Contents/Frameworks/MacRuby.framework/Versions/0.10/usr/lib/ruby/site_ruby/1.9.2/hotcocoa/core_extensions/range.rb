##
# HotCocoa extensions to the Range class
class Range
  ##
  # Create a Cocoa NSRange from a Ruby Range.
  #
  # Since NSRange does not support negative indexing, you _MUST_ include
  # an argument to this method to indicate the length of the object which
  # the range refers to.
  #
  # @example
  #
  #   (0..10).to_NSRange       # => #<NSRange location=0 length=11>
  #   (1..10).to_NSRange       # => #<NSRange location=1 length=10>
  #   (2..-1).to_NSRange(11)   # => #<NSRange location=2 length=9>
  #   (3..-2).to_NSRange(11)   # => #<NSRange location=3 length=7>
  #   (4...-1).to_NSRange(11)  # => #<NSRange location=4 length=6>
  #   (-3...-1).to_NSRange(11) # => #<NSRange location=8 length=2>
  #   (-5..-1).to_NSRange(11)  # => #<NSRange location=6 length=5>
  #
  # @param [Number] length the length of the object which the range represents
  def to_NSRange length = nil
    if (first.negative? or last.negative?) and !length
      raise ArgumentError, 'arg required if range has negative indicies'
    end
    start = (first.negative? ? length + first : first)
    run   = (last.negative?  ? length + last  : last ) - start + (exclude_end? ? 0 : 1)
    NSRange.new start, run
  end
end
