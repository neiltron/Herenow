##
# Object that can register a block to receive arbitrary notifications from
# the default NSNotificationCenter or NSDistributedNotificationCenter.
class HotCocoa::NotificationListener

  ##
  # Map Ruby-ish names for distributed behaviors.
  #
  # @return [Hash{Symbol=>NSNotificationSuspensionBehavior}]
  DistributedBehaviors = {
    drop:                NSNotificationSuspensionBehaviorDrop,
    coalesce:            NSNotificationSuspensionBehaviorCoalesce,
    hold:                NSNotificationSuspensionBehaviorHold,
    deliver_immediately: NSNotificationSuspensionBehaviorDeliverImmediately
  }

  ##
  # Name of the notification to listen for.
  #
  # @return [String]
  attr_reader :name

  ##
  # Name of the notification sender.
  #
  # @return [String]
  attr_reader :sender

  # @return [NSNotificationSuspensionBehavior]
  attr_reader :suspension_behavior

  ##
  # Whether or not the object is registered with the default distributed
  # or regular notification center.
  #
  # @return [Boolean]
  attr_reader :distributed
  alias_method :distributed?, :distributed

  class << self
    ##
    # List of all {HotCocoa::NotificationListener}s.
    #
    # @return [HotCocoa::NotificationListener]
    attr_reader :registered_listeners
  end
  @registered_listeners = []

  ##
  # @todo Would be better to use #define_singleton_method to define a new
  #   {#receive} for each instance?
  #
  # @param [Hash] options
  # @options options [String] :named name of the notification
  # @options options [nil] :sent_by (nil) the signature of the notification
  #   poster (i.e. the method to post notifications asks for a
  #   notificationSender, these values must match up), or set to nil to
  #   receive notifications from anyone
  # @options options [NSNotificationSuspensionBehavior] :when_suspended (:coalesce)
  #   behavior if notification is not set to be being delivered immediately
  #   by the sender, see {HotCocoa::NotificationListener::DistributedBehaviors}
  #   for possible values
  # @options options [Boolean] :distributed (false)
  #
  # @yield the block given here will become the callback for the
  #   notification
  # @yieldparam [String] notification the name of the notification received
  def initialize options = {}, &block
    unless block_given?
      raise ArgumentError, 'You must pass a block to act as the callback'
    end
    @callback = block

    @name                = options[:named]
    @sender              = options[:sent_by]
    @suspension_behavior = DistributedBehaviors[options[:when_suspended] || :coalesce]
    @distributed         = (options[:distributed] == true)
    self.class.registered_listeners << self
    observe
  end

  ##
  # (see #stop_listening)
  # @deprecated Use {#stop_listening} instead. This API is scheduled to
  #             be removed in HotCocoa 0.7.
  def stop_notifications options = {}
    stop_listening options
  end

  ##
  # Stop the listener from listening to any future notifications. The
  # options available here are the same as the {#initialize} methods
  # `:named` and `:sent_by` options.
  def stop_listening options = {}
    if options.has_key?(:named) || options.has_key?(:sent_by)
      notification_center.removeObserver self,
                                   name: options[:named],
                                 object: options[:sent_by]
    else
      notification_center.removeObserver self
    end
    self.class.registered_listeners.delete self
  end

  ##
  # The callback called when a notification is posted. You should not be
  # directly calling this yourself.
  def receive notification
    @callback.call notification
  end


  private

  ##
  # Register for the notification.
  def observe
    if distributed?
      notification_center.addObserver self,
                            selector: 'receive:',
                                name: name,
                              object: sender,
                  suspensionBehavior: suspension_behavior

    else
      notification_center.addObserver self,
                            selector: 'receive:',
                                name: name,
                              object: sender
    end
  end

  ##
  # Returns the notification center to which the listener is registered.
  #
  # @return [NSNotificationCenter,NSDistributedNotificationCenter]
  def notification_center
    @notification_center ||= (distributed ? NSDistributedNotificationCenter.defaultCenter : NSNotificationCenter.defaultCenter)
  end
end

##
# Register for a notification given a block. The options and block given
# here will be passed to {HotCocoa::NotificationListener#initialize};
# this method is merely syntactic sugar.
#
# @return [HotCocoa::NotificationListener
def HotCocoa.on_notification options = {}, &block
  HotCocoa::NotificationListener.new(options, &block)
end
