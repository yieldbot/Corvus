require 'corvus/version'

# Load the defaults
#
module Corvus
  class << self
      attr_writer :ui
        end

  class << self
      attr_reader :ui
        end
                end
