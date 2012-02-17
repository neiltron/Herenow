HotCocoa::Mappings.map application: NSApplication do

  def alloc_with_options opts
    NSApplication.sharedApplication
  end

  def handle_block app
    app.load_application_menu
    yield app
    app.run
  end

  custom_methods do
    # @todo Should we really be hardcoded to require lib/menu and should
    #       it done here?
    def load_application_menu
      require 'lib/menu' # hmmm...

      obj = Object.new
      obj.extend HotCocoa

      setMainMenu obj.application_menu
    rescue LoadError => e
    end

    attr_accessor :name

# @todo What is this about?
=begin
    def menu(path=nil)
      if path
        find_menu(mainMenu, path)
      else
        mainMenu
      end
    end
=end

    def menu
      mainMenu
    end

    def menu= menu
      setMainMenu menu
    end

    def on_hide menu
      hide menu
    end

    def on_about menu
      orderFrontStandardAboutPanel menu
    end

    def on_hide_others menu
      hideOtherApplications menu
    end

    def on_show_all menu
      unhideAllApplications menu
    end

    def on_quit menu
      terminate menu
    end


    private

    def find_menu menu, path
      key = path.keys.first
      value = path.values.first
      menu = menu[key]

      if value.kind_of? Array
        find_menu menu, value.first
      else
        menu[value]
      end
    end
  end

  delegating 'application:delegateHandlesKey:',                       to: :delegate_handles_key?,             parameters: [:delegateHandlesKey]
  delegating 'application:openFile:',                                 to: :open_file,                         parameters: [:openFile]
  delegating 'application:openFiles:',                                to: :open_files,                        parameters: [:openFiles]
  delegating 'application:openFileWithoutUI:',                        to: :open_file_without_ui,              parameters: [:openFileWithoutUI]
  delegating 'application:openTempFile:',                             to: :open_temp_file,                    parameters: [:openTempFile]
  delegating 'application:printFile:',                                to: :print_file
  delegating 'application:printFiles:withSettings:showPrintPanels:',  to: :print_files
  delegating 'application:willPresentError:',                         to: :will_present_error
  delegating 'applicationDidBecomeActive:',                           to: :did_become_active
  delegating 'applicationDidChangeScreenParameters:',                 to: :did_change_screen_parameters
  delegating 'applicationDidFinishLaunching:',                        to: :did_finish_launching
  delegating 'applicationDidHide:',                                   to: :did_hide
  delegating 'applicationDidResignActive:',                           to: :resign_active
  delegating 'applicationDidUnhide:',                                 to: :did_unhide
  delegating 'applicationDidUpdate:',                                 to: :did_update
  delegating 'applicationDockMenu:',                                  to: :dock_menu
  delegating 'applicationOpenUntitledFile:',                          to: :open_untitled_file
  delegating 'applicationShouldHandleReopen:hasVisibleWindows:',      to: :should_handle_reopen?,             parameters: [:hasVisibleWindows]
  delegating 'applicationShouldOpenUntitledFile:',                    to: :should_open_untitled_file?
  delegating 'applicationShouldTerminate:',                           to: :should_terminate?
  delegating 'applicationShouldTerminateAfterLastWindowClosed:',      to: :should_terminate_after_last_window_closed?
  delegating 'applicationWillBecomeActive:',                          to: :will_become_active
  delegating 'applicationWillFinishLaunching:',                       to: :will_finish_launching
  delegating 'applicationWillHide:',                                  to: :will_hide
  delegating 'applicationWillResignActive:',                          to: :will_resign_active
  delegating 'applicationWillTerminate:',                             to: :will_terminate
  delegating 'applicationWillUnhide:',                                to: :will_unhide
  delegating 'applicationWillUpdate:',                                to: :will_update

end
