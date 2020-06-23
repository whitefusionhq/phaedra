require_relative "../phaedra/initializers"

class PhaedraFunction < Phaedra::Base
  def get(params)
    response["Content-Type"] = "text/html; charset=utf-8"
    "<p>This is Interesting. 😁 #{Phaedra.the_time}</p>"
  end
end

Handler = PhaedraFunction