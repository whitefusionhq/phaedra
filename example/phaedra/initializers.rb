require "phaedra"

module Phaedra
  Initializers.register self do
    the_time("123")
  end

  def self.the_time(init = nil)
    @the_time ||= "#{Time.now} + #{init}"
  end
end