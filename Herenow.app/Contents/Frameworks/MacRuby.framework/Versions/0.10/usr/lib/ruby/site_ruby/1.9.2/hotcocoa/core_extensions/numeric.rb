##
# HotCocoa extensions for the Numeric class
class Numeric
  ##
  # Whether or not a number is negative
  def negative?
    self < 0
  end
end
