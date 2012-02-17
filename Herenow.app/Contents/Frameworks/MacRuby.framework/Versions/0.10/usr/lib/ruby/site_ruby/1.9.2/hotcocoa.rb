framework 'Cocoa'

STDOUT.reopen(IO.for_fd(NSFileHandle.fileHandleWithStandardError.fileDescriptor.to_i, 'w'))

##
# HotCocoa is a Cocoa mapping library for MacRuby. It simplifies the use
# of complex Cocoa classes using DSL techniques.
module HotCocoa; end

require 'hotcocoa/version'
require 'hotcocoa/core_extensions'
require 'hotcocoa/mappings'
require 'hotcocoa/target_action_convenience'
require 'hotcocoa/behaviors'
require 'hotcocoa/mapping_methods'
require 'hotcocoa/mapper'
require 'hotcocoa/layout_view'
require 'hotcocoa/delegate_builder'
require 'hotcocoa/notification_listener'
require 'hotcocoa/data_sources'
require 'hotcocoa/kvo_accessors'
require 'hotcocoa/attributed_string_helpers'

HotCocoa::Mappings.reload
