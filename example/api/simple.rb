require_relative "../phaedra/initializers"

class PhaedraFunction < Phaedra::Base
  def get(params)
    response["Content-Type"] = "text/html; charset=utf-8"
    "<p>😁 #{Phaedra.the_time} - #{ENV["PHAEDRA_ENV"]} - #{Time.new}</p>"
  end
end

Handler = PhaedraFunction