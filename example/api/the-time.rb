require "phaedra"

class PhaedraFunction < Phaedra::Base
  before_action :earlier_stuff

  def get(params)
    "The Current Time is: #{Time.new} and Search Param is #{params[:search]}."
  end

  def post(params)
    {message: "POST works!", params: params}
  end
  
  private

  def earlier_stuff
    request.query["search"] += " SEARCH!" if request.query["search"]

    if request.body
      request.body.sub!("Works", "Lurks")
    end
  end
end
