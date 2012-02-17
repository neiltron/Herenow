module HotCocoa

  ##
  # Builds a delegate for a control at runtime by creating a generic object
  # and adding singleton methods for each given delegate method; it then
  # tells the control to delegate to that created object.
  class DelegateBuilder

    ##
    # The object that needs a delegate
    #
    # @return
    attr_reader :control

    ##
    # Delegate methods which are assumed to be implemented and therefore
    # __MUST__ be given at least a stub
    #
    # @return [Array<SEL,String>]
    attr_reader :required_methods

    ##
    # The delegate object
    #
    # @return [Object]
    attr_reader :delegate

    # @param control the object which needs a delegate
    # @param [Array<SEL,String>] required_methods
    def initialize control, required_methods
      @control          = control
      @required_methods = required_methods
      @delegate         = Object.new
    end

    ##
    # Add a delegated method for {#control} to {#delegate}
    def add_delegated_method block, selector_name, *parameters
      clear_delegate if required_methods.empty?

      delegate_method_builder.add_delegated_method block, selector_name, *parameters

      required_methods.delete(selector_name)
      set_delegate if required_methods.empty?
    end

    def delegate_to object, *method_names
      method_names.each do |method_name|
        control.send(method_name, &object.method(method_name)) if object.respond_to?(method_name)
      end
    end


    private

    ##
    # Reset the delegate for {#control} to `nil`.
    def clear_delegate
      control.setDelegate(nil) if control.delegate
    end

    ##
    # Set the delegate for {#control} to {#delegate}
    def set_delegate
      control.setDelegate(delegate)
    end

    def delegate_method_builder
      @delegate_method_builder ||= DelegateMethodBuilder.new(@delegate)
    end

  end


  class DelegateMethodBuilder

    def initialize target
      @target = target
    end

    def add_delegated_method block, selector_name, *parameters
      bind_block_to_delegate_instance_variable(selector_name, block)
      create_delegate_method(selector_name, parameters)
    end

    def bind_block_to_delegate_instance_variable selector_name, block
      @target.instance_variable_set(block_instance_variable_for(selector_name), block)
    end

    ##
    # @todo GET RID OF EVAL
    def create_delegate_method selector_name, parameters
      eval %{
        def @target.#{parameterize_selector_name(selector_name)}
          #{block_instance_variable_for(selector_name)}.call(#{parameter_values_for_mapping(selector_name, parameters)})
        end
      }
    end

    ##
    # Returns an instance variable name to be used for the delegate method
    # currently being built.
    #
    # @return [String]
    def block_instance_variable_for selector_name
      "@block_#{selector_name.gsub(':', "_")}"
    end

    ##
    # Take an Objective-C selector and create a parameter list to be used
    # in creating method's using #eval
    #
    # @example
    #   parameterize_selector_name('myDelegateMethod') # => 'myDeletageMethod'
    #   parameterize_selector_name('myDelegateMethod:withArgument:') # => 'myDeletageMethod p1, withArgument:p2'
    #
    # @param [String] selector_name
    # @return [String]
    def parameterize_selector_name selector_name
      return selector_name unless selector_name.include?(':')

      params = selector_name.split(':')
      result = "#{params.shift} p1"
      params.each_with_index do |param, i|
        result << ",#{param}:p#{i + 2}"
      end
      result
    end

    def parameter_values_for_mapping selector_name, parameters
      return if parameters.empty?

      result = []
      selector_params = selector_name.split(':')
      parameters.each do |parameter|
        if (dot = parameter.index('.'))
          result << "p#{selector_params.index(parameter[0...dot]) + 1}#{parameter[dot..-1]}"
        else
          parameter = parameter.to_s
          raise "Error in delegate mapping: '#{parameter}' is not a valid parameter of method '#{selector_name}'" if selector_params.index(parameter).nil?
          result << "p#{selector_params.index(parameter) +  1}"
        end
      end
      result.join(', ')
    end

  end

end
