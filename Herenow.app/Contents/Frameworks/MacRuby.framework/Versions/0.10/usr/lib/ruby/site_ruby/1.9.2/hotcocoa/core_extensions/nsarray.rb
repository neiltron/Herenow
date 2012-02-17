##
# HotCocoa extensions for the NSArray class
class NSArray
  ##
  # Equivalent to `#[1]`, borrowed from Active Support.
  def second
    at(1)
  end

  ##
  # Equivalent to `#[2]`, borrowed from Active Support.
  def third
    at(2)
  end
end
