require "phaedra"

class PhaedraFunction < Phaedra::Base
  def get(params)
    response["Content-Type"] = "text/html; charset=utf-8"
    "<p>This is Interesting. 😁</p>"
  end
end

Handler = PhaedraFunction