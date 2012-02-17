##
# Does most of the heavy lifiting when it comes to HotCocoa mappings.
class HotCocoa::Mappings::Mapper

  class << self
    ##
    # Add mappings to a class so instances of the class can benefit from
    # HotCocoa features. Usually called by {HotCocoa::Behaviors.included}.
    #
    # @param [Class] klass
    # @return [nil] do not count on a return value from this method
    def map_class klass
      new(klass).include_in_class
    end

    ##
    # Create a mapper for the given `klass` and assign it to the
    # given `builder_method`.
    #
    # @param [Class] klass
    # @param [Symbol] builder_method
    # @return [HotCocoa::Mappings::Mapper]
    def map_instances_of klass, builder_method, &block
      new(klass).map_method(builder_method, &block)
    end

    ##
    # Cached bindings modules.
    #
    # @return [Hash{Symbol=>Module}]
    attr_reader :bindings_modules

    ##
    # Cached delegate modules.
    #
    # @return [Hash{Symbol=>Module}]
    attr_reader :delegate_modules
  end

  ##
  # Performance hack. Put mutable objects that are constant into a
  # constant to avoid having to `#dup`.
  #
  # @return [String]
  SET = 'set'

  # they need to be initialized
  @bindings_modules = {}
  @delegate_modules = {}

  # @return [Class]
  attr_reader :control_class

  ##
  # @todo We do not use the cached `builder_method` attribute unless
  #       you count tests. So maybe we should get rid of it?
  #
  # The name which the mapping goes by (e.g. :window for NSWindow)
  #
  # @return [Symbol]
  attr_reader :builder_method

  ##
  # Singleton class for the mapper instance
  #
  # @return [Class]
  attr_reader :control_module

  ##
  # Whether or not bindings should be mapped for an instance of
  # the mapped class.
  #
  # @return [Boolean]
  attr_accessor :map_bindings

  # @param [Class] klass the class that is being mapped
  def initialize klass
    @control_class = klass
  end

  ##
  # Add HotCocoa features to a class. The `control_class` that the mapper
  # was initialized with will receive features for all ancestors that
  # have mappings.
  def include_in_class
    @extension_method = :include
    customize @control_class
  end

  ##
  # Create the mapping method named `builder_method`.
  #
  # @param [Symbol] builder_method
  # @yield
  # @return [HotCocoa::Mappings::Mapper]
  def map_method builder_method, &block
    @extension_method = :extend
    @builder_method   = builder_method

    # @todo use self.singleton_class instead (not implemented in MacRuby yet)
    mod = (class << self; self; end)
    mod.extend HotCocoa::MappingMethods
    mod.module_eval &block

    @control_module = mod
    # put self in a variable, because context of self changes inside the define_method block
    inst = self
    HotCocoa.send :define_method, builder_method do |args = {}, &control_block|
      map = inst.remap_constants args

      inst.map_bindings = map.delete :map_bindings
      default_empty_rect_used = (CGRectZero == map[:frame])

      control = if inst.respond_to? :init_with_options
                  inst.init_with_options(inst.control_class.alloc, map)
                else
                  inst.alloc_with_options(map)
                end

      inst.customize control

      map.each do |key, value|
        if control.respond_to? "#{key}="
          control.send "#{key}=", value

        elsif control.respond_to? key
          new_key = (key.start_with?(SET) ? key : "set#{key[0].capitalize}#{key[1..-1]}")
          if control.respond_to? new_key
            control.send new_key, value

          else
            control.send key

          end
        elsif control.respond_to? "set#{key.camel_case}"
          control.send "set#{key.camel_case}", value

        else
          NSLog("Unable to map #{key} as a method")

        end
      end

      if default_empty_rect_used
        control.sizeToFit if control.respondsToSelector :sizeToFit
      end

      if control_block
        if inst.respond_to? :handle_block
          inst.handle_block control, &control_block
        else
          control_block.call control
        end
      end

      control
    end

    # make the function callable using HotCocoa.xxxx
    HotCocoa.send :module_function, builder_method
    # module_function makes the instance method private, but we want it to stay public
    HotCocoa.send :public, builder_method
    self
  end

  ##
  # Returns a hash of constant hashes that were inherited from ancestors
  # that have also been mapped.
  #
  # @return [Hash{Hash}]
  def inherited_constants
    constants = {}
    each_control_ancestor do |ancestor|
      constants.merge! ancestor.control_module.constants_map
    end
    constants
  end

  def inherited_delegate_methods
    delegate_methods = {}
    each_control_ancestor do |ancestor|
      delegate_methods.merge! ancestor.control_module.delegate_map
    end
    delegate_methods
  end

  ##
  # Return the `custom_methods` module for the class we are instantiating,
  # as well as all of its ancestors.
  #
  # @return [Array<Module>]
  def inherited_custom_methods
    methods = []
    each_control_ancestor do |ancestor|
      if ancestor.control_module.custom_methods
        methods << ancestor.control_module.custom_methods
      end
    end
    methods
  end

  ##
  # Iterates over the ancestor chain for the class being mapped and
  # yields for each ancestor that also has a mapping.
  #
  # Classes are yielded from the descending order (from the super class
  # to the sub class).
  #
  # @yield
  # @yieldparam [Class] a class in the inheritance chain
  def each_control_ancestor
    control_class.ancestors.reverse.each do |ancestor|
      HotCocoa::Mappings.mappings.values.each do |mapper|
        yield mapper if mapper.control_class == ancestor
      end
    end
  end

  ##
  # Apply customizations to defined in a mapping to the control. The
  # control is either an instance of the class or the class itself,
  # depending on how things were setup.
  #
  # @param control
  def customize control
    inherited_custom_methods.each do |custom_methods|
      control.send @extension_method, custom_methods
    end
    decorate_with_delegate_methods control
    decorate_with_bindings_methods control
  end

  ##
  # Add the delegate method hooks. For #include they become instance methods
  # and for #extend they become singleton methods.
  def decorate_with_delegate_methods control
    control.send @extension_method, delegate_module_for_control_class
  end

  ##
  # Create a module to hold the delegate object. The module can then be
  # mixed in so that a control instance can use HotCocoa style delegation.
  #
  # The style of delegation that HotCocoa supports works by creating an
  # Object instance and then defining delegate methods as singleton
  # methods on that object. Then the object is set to be the delegate
  # of the control.
  #
  # The generated module is cached for later reuse.
  #
  # @return [Module] the generated delegate module
  def delegate_module_for_control_class
    delegate_module = HotCocoa::Mappings::Mapper.delegate_modules[control_class]
    return delegate_module if delegate_module

    delegate_module  = Module.new
    required_methods = []
    delegate_methods = inherited_delegate_methods

    if delegate_methods.size > 0
      delegate_methods.each do |delegate_method, mapping|
        required_methods << delegate_method if mapping[:required]
      end

      delegate_methods.each do |delegate_method, mapping|
        parameters = mapping[:parameters] ? mapping[:parameters] : []

        # kind of a hack, giving a block directly to define_method is not working
        # for some odd reason, possibly a bug in MacRuby
        callback = Proc.new do |&block|
          raise 'Must pass in a block to use this delegate method' unless block

          @_delegate_builder ||= HotCocoa::DelegateBuilder.new(self, required_methods)
          @_delegate_builder.add_delegated_method(block, delegate_method, *parameters)
        end
        delegate_module.send :define_method, mapping[:to], callback
      end

      delegate_module.send :define_method, :delegate_to do |object|
        @_delegate_builder ||= HotCocoa::DelegateBuilder.new(self, required_methods)
        @_delegate_builder.delegate_to(object, *delegate_methods.values.map { |method| method[:to].to_sym })
      end
    end

    HotCocoa::Mappings::Mapper.delegate_modules[control_class] = delegate_module
  end

  # @return [nil] do not count on a return value
  def decorate_with_bindings_methods control
    return if control_class == NSApplication
    if @map_bindings
      control.send @extension_method, bindings_module_for_control(control)
    end
  end

  ##
  # Create a module to hold all bindings setters. The bindings module is
  # meant to assist with setting up Cocoa Bindings by providing a simplified
  # and more Ruby-ish interface.
  #
  # Read more about [Key-Value Binding](http://developer.apple.com/library/mac/#documentation/Cocoa/Reference/ApplicationKit/Protocols/NSKeyValueBindingCreation_Protocol/Reference/Reference.html).
  #
  # If the control has no exposed bindings, then an empty module will
  # be generated.
  #
  # In either case, once a module is generated, it is cached for later use.
  #
  # @return [Module] the generated bindings module
  def bindings_module_for_control control
    bindings_module = HotCocoa::Mappings::Mapper.bindings_modules[control_class]
    return bindings_module if bindings_module

    instance = if control == control_class
                 control_class.alloc.init
               else
                 control
               end

    bindings_module = Module.new
    instance.exposedBindings.each do |exposed_binding|
      p = Proc.new do |value|
        if value.kind_of? Hash
          options = value.delete :options
          bind "#{exposed_binding}", toObject: value.keys.first,
                                  withKeyPath: value.values.first,
                                      options: options
        else
          send "set#{exposed_binding.camel_case}", value
        end
      end
      bindings_module.send :define_method, "#{exposed_binding.underscore}=", p
    end

    HotCocoa::Mappings::Mapper.bindings_modules[control_class] = bindings_module
  end

  ##
  # Takes a hash and processes symbols, if the symbol is a mapped
  # constant then it will be swapped with the value of the constant.
  #
  # This is how constant mappings are used in Hot Cocoa.
  #
  # @param [Hash] tags
  # @return [Hash]
  def remap_constants tags
    constants = inherited_constants
    if control_module.defaults
      control_module.defaults.each do |key, value|
        tags[key] = value unless tags.has_key? key
      end
    end

    result = {}
    tags.each do |tag, value|
      if constants[tag]
        result[tag] = value.kind_of?(Array) ?
          value.inject(0) { |a, i| a|constants[tag][i] } :
          constants[tag][value]
      else
        result[tag] = value
      end
    end
    result
  end

end
