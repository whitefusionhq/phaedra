module Phaedra
  Initializers.register self, priority: :high do
    environment
  end

  def self.environment
    @environment ||= ENV.fetch("PHAEDRA_ENV", :development).to_sym
  end
end