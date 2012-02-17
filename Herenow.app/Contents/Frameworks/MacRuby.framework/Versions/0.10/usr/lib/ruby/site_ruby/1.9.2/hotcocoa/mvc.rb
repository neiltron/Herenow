require 'hotcocoa'

class HotCocoaApplication
  include HotCocoa

  # @return [NSApplication]
  attr_accessor :shared_application

  # @return []
  attr_accessor :application_controller

  # @return []
  attr_accessor :controllers

  class << self
    ##
    # The singleton instance of the application.
    #
    # @return [HotCocoaApplication]
    attr_accessor :instance
  end

  def initialize application_file
    HotCocoaApplication.instance = self

    @controllers = {}
    load_controllers_and_views(directory_of(application_file))

    @shared_application = application(ApplicationView.options[:application])
    @shared_application.load_application_menu
    @application_controller = controller(:application_controller)

    shared_application.delegate_to(application_controller)
  end

  def start
    @shared_application.run
  end

  def controller controller_name
    controller_name_string = controller_name.to_s

    controller_class = if Object.const_get(controller_name_string !~ /_/ && controller_name_string =~ /[A-Z]+.*/)
      controller_name_string
    else
      controller_name_string.split('_').map { |e| e.capitalize }.join
    end

    @controllers[controller_name] || create_controller_instance(controller_name, controller_class)
  end

  private

  def create_controller_instance controller_name, controller_class
    controller_instance = controller_class.new self

    @controllers[controller_name] = controller_instance

    controller_instance.application_window
    controller_instance
  end

  def directory_of application_file
    File.dirname(File.expand_path(application_file))
  end

  def load_controllers_and_views directory
    Dir.glob(File.join(directory, 'controllers/**/*.rb')).each do |controller_file|
      load(controller_file)
    end
    Dir.glob(File.join(directory, 'views/**/*.rb')).each do |view_file|
      load(view_file)
    end
  end
end

class HotCocoaController

  class << self
    attr_reader :view_instances
  end
  @view_instances = {}

  attr_reader :application

  def initialize application
    @application = application
  end

  def application_window
    @application.application_controller.application_window
  end
end

class HotCocoaApplicationController < HotCocoaController
  def application_window
    @application_window ||= ApplicationWindow.new(self).application_window
  end
end

class HotCocoaWindow
  attr_reader :application_controller
  attr_reader :application_window

  def initialize application_controller
    @application_controller = application_controller
    render
  end

  def render
    @application_window = HotCocoa.window(ApplicationView.options[:window])
    @application_window.delegate_to(application_controller)
    @application_window.view << application_controller.application_view
  end
end

class HotCocoaView < HotCocoa::LayoutView
  DefaultLayoutOptions = { expand: [:width, :height] }

  module ClassMethods
    def controller name = nil
      if name
        @name = name
      else
        @name || :application_controller
      end
    end

    def options options = nil
      if options
        @options = options
      else
        @options
      end
    end
  end

  def self.inherited klass
    klass.extend(ClassMethods)
    klass.send(:include, HotCocoa::Behaviors)
    class_name = klass.name.underscore

    HotCocoaController.class_eval %{
      def #{class_name}
        unless HotCocoaController.view_instances[:#{class_name}]
          HotCocoaController.view_instances[:#{class_name}] = #{klass.name}.alloc.initWithFrame(CGRectZero)
          HotCocoaController.view_instances[:#{class_name}].setup_view
        end
        HotCocoaController.view_instances[:#{class_name}]
      end
    }, __FILE__, __LINE__
  end

  attr_reader :controller

  def setup_view
    unless @controller
      @controller = class_controller
      self.layout = layout_options
      render
    end
  end


  private

  def class_controller
    HotCocoaApplication.instance.controller(self.class.controller)
  end

  def layout_options
    options = if self.class.options && self.class.options[:layout]
                self.class.options[:layout]
              else
                DefaultLayoutOptions
              end
  end
end

class ApplicationWindow < HotCocoaWindow
end

class Application < HotCocoaApplication
end
