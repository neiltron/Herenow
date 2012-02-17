module HotCocoa
  class LayoutOptions
    VALID_EXPANSIONS = [nil, :height, :width, [:height, :width], [:width, :height]]

    attr_accessor :defaults_view

    # @return [NSView]
    attr_reader   :view

    # @param [NSView] view
    # @param [Hash] options
    #
    # @option options [Boolean] :start (true) Whether the view is packed
    #   at the start or the end of the packing view
    #
    # @option options [Symbol] :expand (nil) Whether the view's first
    #   dimension (width for horizontal and height for vertical) should
    #   be expanded to the maximum possible size, and should be variable
    #   according to the packing view frame. Values can be `:height`,
    #   `:width`, or `[:height, :width]`
    #
    # @option options [Float] :padding (0.0) Controls the padding area
    #   around the view. `:padding` controls all the areas, while options
    #   like `:left_padding` only control the left side--if `:padding`
    #   is set, other padding flags are ignored
    # @option options [Fload] :left_padding (0.0)
    # @option options [Float] :right_padding (0.0)
    # @option options [Float] :top_padding (0.0)
    # @option options [Float] :bottom_padding (0.0)
    #
    # @option options [Symbol] :align Controls the view's alignment if
    #   its not expanded in the other dimension; modes can be:
    #
    #   * `:left`
    #   For horizontal layouts, align left
    #
    #   * `:center`
    #   Align center for horizontal or vertical layouts
    #
    #   * `:right`
    #   For horizontal layouts, align right
    #
    #   * `:top`
    #   For vertical layouts, align top
    #
    #   * `:bottom`
    #   For vertical layouts, align bottom
    #
    # @option options [NSView] :defaults_view not sure yet...
    def initialize view, options = {}
      @view           = view
      @start          = options[:start]
      @expand         = options[:expand]
      @padding        = options[:padding]
      @left_padding   = @padding || options[:left_padding]
      @right_padding  = @padding || options[:right_padding]
      @top_padding    = @padding || options[:top_padding]
      @bottom_padding = @padding || options[:bottom_padding]
      @align          = options[:align]
      @defaults_view  = options[:defaults_view]
    end

    def start= value
      return if value == @start
      @start = value
      update_layout_views!
    end

    def start?
      return @start unless @start.nil?
      if in_layout_view?
        @view.superview.default_layout.start?
      else
        true
      end
    end

    def expand= value
      return if value == @expand
      unless VALID_EXPANSIONS.include?(value)
        raise ArgumentError, "Expand must be nil, :height, :width or [:width, :height] not #{value.inspect}"
      end
      @expand = value
      update_layout_views!
    end

    def expand
      return @expand unless @expand.nil?
      if in_layout_view?
        @view.superview.default_layout.expand
      else
        false
      end
    end

    def expand_width?
      e = self.expand
      e == :width || (e.respond_to?(:include?) && e.include?(:width))
    end

    def expand_height?
      e = self.expand
      e == :height || (e.respond_to?(:include?) && e.include?(:height))
    end

    def left_padding= value
      return if value == @left_padding
      @left_padding = value
      @padding = nil
      update_layout_views!
    end

    def left_padding
      return @left_padding unless @left_padding.nil?
      if in_layout_view?
        @view.superview.default_layout.left_padding
      else
        padding
      end
    end

    def right_padding= value
      return if value == @right_padding
      @right_padding = value
      @padding = nil
      update_layout_views!
    end

    def right_padding
      return @right_padding unless @right_padding.nil?
      if in_layout_view?
        @view.superview.default_layout.right_padding
      else
        padding
      end
    end

    def top_padding= value
      return if value == @top_padding
      @top_padding = value
      @padding = nil
      update_layout_views!
    end

    def top_padding
      return @top_padding unless @top_padding.nil?
      if in_layout_view?
        @view.superview.default_layout.top_padding
      else
        padding
      end
    end

    def bottom_padding= value
      return if value == @bottom_padding
      @bottom_padding = value
      @padding = nil
      update_layout_views!
    end

    def bottom_padding
      return @bottom_padding unless @bottom_padding.nil?
      if in_layout_view?
        @view.superview.default_layout.bottom_padding
      else
        padding
      end
    end

    def align
      return @align unless @align.nil?
      if in_layout_view?
        @view.superview.default_layout.align
      else
        :left
      end
    end

    def align= value
      return if value == @align
      @align = value
      update_layout_views!
    end

    def padding= value
      return if value == @padding
      @right_padding = @left_padding = @top_padding = @bottom_padding = value
      @padding = value
      update_layout_views!
    end

    def padding
      @padding || 0.0
    end

    def inspect
      "#<#{self.class} " +
        "start=#{start?}, " +
        "expand=#{expand.inspect}, " +
        "padding=[l:#{left_padding}, r:#{right_padding}, t:#{top_padding}, b:#{bottom_padding}], " +
        "align=#{align.inspect}, " +
        "view=#{view.inspect}>"
    end

    def update_layout_views!
      @view.superview.relayout! if in_layout_view?
      @defaults_view.relayout!  if @defaults_view
    end

    private

    def in_layout_view?
      @view && @view.superview.kind_of?(LayoutView)
    end
  end

  ##
  # @todo Why aren't we mixing in {HotCocoa::Behaviors}?
  #
  # HotCocoa layout managing class. This class is responsible for keeping
  # track of your UI layout, including adding, removing, and updating
  # subviews.
  class LayoutView < NSView

    ##
    # Set some default values and call the super class initializer.
    #
    # @param [CGRect, Array<Number, Number, Number, Number>]
    def initWithFrame frame
      super
      @mode    = :vertical
      @spacing = 10
      @margin  = 10
      self
    end

    # @return [NSColor]
    attr_accessor :frame_color

    ##
    # Whether or not the layout mode is vertical.
    def vertical?
      @mode == :vertical
    end

    ##
    # Whether or not the layout mode is horizontal.
    def horizontal?
      @mode == :horizonal
    end

    ##
    # Set the layout mode. The default value is `:vertical`, you can
    # change it to be `:horizontal` if you want.
    #
    # @param [Symbol]
    def mode= new_mode
      unless [:horizontal, :vertical].include?(new_mode)
        raise ArgumentError, "invalid mode value #{new_mode}"
      end

      if new_mode != @mode
        @mode = new_mode
        relayout!
      end
    end

    ##
    # Set the default layout options. The options should follow the format
    # that would be given to {HotCocoa::LayoutOptions}.
    #
    # @param [Hash]
    def default_layout= options
      options[:defaults_view] = self
      @default_layout = LayoutOptions.new(nil, options)
      relayout!
    end

    def default_layout
      @default_layout ||= LayoutOptions.new(nil, defaults_view: self)
    end

    # @return [Fixnum]
    attr_reader :spacing

    ##
    # Change the spacing between subviews.
    #
    # @param [Number]
    def spacing= new_spacing
      if new_spacing != @spacing
        @spacing = new_spacing.to_i
        relayout!
      end
    end

    # @return [Fixnum]
    attr_reader :margin

    ##
    # Change the margin size for the view.
    #
    # @param [Fixnum]
    def margin= new_margin
      if new_margin != @margin
        @margin = new_margin.to_i
        relayout!
      end
    end

    ##
    # Add a new subview to the layout view.
    #
    # @param [NSView]
    def addSubview view
      super
      if view.respond_to? :layout
        relayout!
      else
        raise ArgumentError, "view #{view} does not support the #layout method"
      end
    end
    alias_method :<<, :addSubview

    ##
    # Remove a subview from the layout.
    #
    # @param [NSView]
    def remove_view view
      unless subviews.include? view
        raise ArgumentError, "view #{view} not a subview of this LayoutView"
      end
      view.removeFromSuperview
      relayout!
    end
    alias_method :remove, :remove_view

    ##
    # Remove all the subviews from the layout view.
    def remove_all_views
      subviews.each { |view| view.removeFromSuperview }
      relayout!
    end

    ##
    # This is a callback, you don't need to worry about it.
    def drawRect frame
      if frame_color
        frame_color.set
        NSFrameRect(frame)
      end
    end

    ##
    # This is a callback, you don't need to worry about it.
    def setFrame frame
      super(frame, &nil)
      relayout!
    end
    alias_method :frame=, :setFrame

    ##
    # This is a callback, you don't need to worry about it.
    def setFrameSize size
      super(size, &nil)
      relayout!
    end
    alias_method :size=, :setFrameSize

    ##
    # @todo This method could be optimized quite a bit, I think.
    #
    # Figure out how to layout all the subviews. This is the meat of the
    # class.
    def relayout!
      view_size      = frameSize
      end_dimension  = vertical? ? view_size.height : view_size.width
      end_dimension -= (@margin * 2)
      dimension      = @margin

      expandable_size = calc_expandable_size(end_dimension)

      subviews.each do |view|
        next unless can_layout? view

        options = view.layout
        subview_size = view.frameSize
        view_frame = NSMakeRect(0, 0, *subview_size)
        subview_dimension = vertical? ? subview_size.height : subview_size.width

        if vertical?
          primary_dimension   = HEIGHT
          secondary_dimension = WIDTH
          primary_axis        = X
          secondary_axis      = Y
          expand_primary      = EXPAND_HEIGHT
          expand_secondary    = EXPAND_WIDTH
          padding_first       = LEFT_PADDING
          padding_second      = RIGHT_PADDING
          padding_third       = BOTTOM_PADDING
          padding_fourth      = TOP_PADDING
        else
          primary_dimension   = WIDTH
          secondary_dimension = HEIGHT
          primary_axis        = Y
          secondary_axis      = X
          expand_primary      = EXPAND_WIDTH
          expand_secondary    = EXPAND_HEIGHT
          padding_first       = TOP_PADDING
          padding_second      = BOTTOM_PADDING
          padding_third       = LEFT_PADDING
          padding_fourth      = RIGHT_PADDING
        end

        view_frame.origin.send("#{primary_axis}=", @margin)
        view_frame.origin.send("#{secondary_axis}=", (options.start? ? dimension : (end_dimension - subview_dimension)))

        if options.send(expand_primary)
          view_frame.size.send("#{primary_dimension}=", expandable_size)
          subview_dimension = expandable_size
        end

        if options.send(expand_secondary)
          view_frame.size.send("#{secondary_dimension}=",
                  view_size.send(secondary_dimension) - (2 * @margin) -
                                    options.send(padding_first) - options.send(padding_second))
        else

          case options.align
          when :left, :bottom
            # Nothing to do
          when :center
            view_frame.origin.send("#{primary_axis}=", (view_size.send(secondary_dimension) / 2.0) - (subview_size.send(secondary_dimension) / 2.0))

          when :right, :top
            view_frame.origin.send("#{primary_axis}=", view_size.send(secondary_dimension) -
                                      subview_size.send(secondary_dimension) - @margin)
          end
        end

        if $DEBUG
          puts "view #{view} options #{options.inspect} " +
               "final frame [#{view_frame.origin.x}, #{view_frame.origin.y}, "+
               "#{view_frame.size.width}x#{view_frame.size.height}]"
        end

        view_frame.origin.x += options.left_padding
        view_frame.origin.y += options.bottom_padding

        if options.start?
          dimension += subview_dimension + @spacing
          dimension += options.send(padding_third) + options.send(padding_fourth)
        else
          end_dimension -= subview_dimension + @spacing
        end

        view.frame = view_frame
      end
    end


    private

    # @private
    HEIGHT         = 'height'
    # @private
    WIDTH          = 'width'
    # @private
    X              = 'x'
    # @private
    Y              = 'y'
    # @private
    EXPAND_HEIGHT  = 'expand_height?'
    # @private
    EXPAND_WIDTH   = 'expand_width?'
    # @private
    LEFT_PADDING   = 'left_padding'
    # @private
    RIGHT_PADDING  = 'right_padding'
    # @private
    BOTTOM_PADDING = 'bottom_padding'
    # @private
    TOP_PADDING    = 'top_padding'

    ##
    # Calculate the maximum size that a subview can take up in the layout.
    def calc_expandable_size end_dimension
      expandable_size  = end_dimension
      expandable_views = 0

      subviews.each do |view|
        next unless can_layout? view

        if vertical?
          size    = view.frameSize.height
          expand  = view.layout.expand_height?
          padding = view.layout.top_padding + view.layout.bottom_padding
        else
          size    = view.frameSize.width
          expand  = view.layout.expand_width?
          padding = view.layout.left_padding + view.layout.right_padding
        end

        if expand
          expandable_views += 1
        else
          expandable_size  -= size
          expandable_size  -= @spacing
        end

        expandable_size -= padding
      end

      expandable_size /= expandable_views
      expandable_size
    end

    ##
    # @note NSView defines `#layout` in Lion for AutoLayout, and so this
    #       will almost always return true on Lion, even if it should
    #       not. THIS IS A BUG.
    #
    # Whether or not the view can be used
    def can_layout? view
      view.respond_to?(:layout) && !view.layout.nil?
    end

  end
end
