require 'fileutils'

##
# This class creates new projects given the directory to put them
# into and the name for the new project.
class HotCocoa::Template
  include FileUtils

  ##
  # Directories that need to be created for a new app project.
  #
  # @return [Array<String>]
  DIRECTORIES    = [ 'lib', 'resources' ]

  ##
  # Project files which can be directly copied to a new project.
  #
  # @return [Array<String>]
  COPIED_FILES   = [
                    'lib/menu.rb',
                    'resources/HotCocoa.icns'
                   ]

  ##
  # Project files which contain tokens that need to be substituted
  # before being copied to a new project.
  #
  # @return [Array<String>]
  FILTERED_FILES = [
                    'Rakefile',
                    '__APPLICATION_NAME__.appspec',
                    'lib/application.rb',
                   ]

  ##
  # The path to the HotCocoa app template in the HotCocoa source files
  #
  # @return [String]
  def self.template_directory
    file = $LOADED_FEATURES.find { |file| file.match /hotcocoa\/template\.rbo?$/ }
    File.expand_path(File.join(File.dirname(file), '../../template'))
  end

  # @param [String] dir where to put the project
  # @param [String] name name for the project
  def initialize dir, name
    @directory = dir
    @app_name  = name
  end

  ##
  # Create the project!
  def copy!
    @template = self.class.template_directory
    make_directories
    copy_resources
    copy_sources
  end


  private

  ##
  # Create the directory structure for a new app.
  def make_directories
    mkdir_p @directory
    DIRECTORIES.each do |dir|
      mkdir_p File.join(@directory, dir)
    end
  end

  ##
  # Copy all files that do not need to have tokens substituted.
  def copy_resources
    COPIED_FILES.each do |file|
      cp File.join(@template, file), File.join(@directory, file)
    end
  end

  ##
  # Copy all files that need to have tokens substituted.
  def copy_sources
    company_name = ENV['USER'] || 'yourcompany'

    FILTERED_FILES.each do |file|
      input = File.read File.join(@template, file)
      input.gsub! /__APPLICATION_NAME__/, @app_name
      input.gsub! /__COMPANY_NAME__/, company_name

      outname = file.gsub /__APPLICATION_NAME__/, @app_name
      outname = File.join(@directory, outname)
      File.open(outname, 'w') { |out| out.write input }
    end
  end

end
