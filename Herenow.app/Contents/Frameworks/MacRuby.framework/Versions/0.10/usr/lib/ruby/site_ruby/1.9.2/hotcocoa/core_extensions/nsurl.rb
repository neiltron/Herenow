##
# HotCocoa extensions for the NSURL class
class NSURL
  alias_method :to_s, :absoluteString
  alias_method :inspect, :absoluteString
end
