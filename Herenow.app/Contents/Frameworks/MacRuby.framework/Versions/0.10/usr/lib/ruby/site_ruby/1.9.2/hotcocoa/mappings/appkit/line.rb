##
# Abstract mapping of NSBezierPath that only creates a straight line from
# one point to another.
HotCocoa::Mappings.map line: NSBezierPath do

  # @key [CGPoint, Array(Float,Float)] p1
  # @key [CGPoint, Array(Float,Float)] p2
  def alloc_with_options options
    path = NSBezierPath.bezierPath
    path.moveToPoint options.delete :p1
    path.lineToPoint options.delete :p2
    path.stroke
    path
  end

end
