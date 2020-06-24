require "phaedra"
require "securerandom"

module Phaedra
  module Shared
    Initializers.register self do
      the_time SecureRandom.hex(10)
    end

    def self.the_time(init = nil)
      @the_time ||= "#{Time.now} (random seed: #{init})"
    end
  end
end