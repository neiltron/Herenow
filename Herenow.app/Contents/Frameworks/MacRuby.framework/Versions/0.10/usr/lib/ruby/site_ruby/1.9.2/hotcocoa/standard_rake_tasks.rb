$stderr.puts <<EOM
The old build system, which uses standard_rake_tasks.rb, is deprecated in favour
of a more easily configurable build system as of HotCocoa 0.6. The old build
system will be removed in HotCocoa 0.7.

You can update your existing project by looking at the new project template, which
can be found on Github:

     https://github.com/ferrous26/hotcocoa/blob/master/template

EOM

AppConfig = HotCocoa::ApplicationBuilder::Configuration.new('config/build.yml')

desc 'Build a deployable version of the application'
task :deploy do
  HotCocoa::ApplicationBuilder.build AppConfig, deploy: true
end

desc 'Build the application'
task :build do
  HotCocoa::ApplicationBuilder.build AppConfig
end

desc 'Build and execute the application'
task :run => [:build] do
  `"./#{AppConfig.name}.app/Contents/MacOS/#{AppConfig.name.gsub(/ /, '')}"`
end

desc 'Cleanup build files'
task :clean do
  sh "/bin/rm -rf '#{AppConfig.name}.app'"
end
