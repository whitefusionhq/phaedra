require_relative "../phaedra/initializers"

class PhaedraFunction < Phaedra::Base
  before_action :earlier_stuff

  def get(params)
    "The ?search param is #{params[:search] || "-missing-"}"
  end

  def post(params)
    {message: "POST works!", params: params}
  end
  
  private

  def earlier_stuff
    request.query["search"] += " (nice!)" if request.query["search"]

    if request.body
      request.body.sub!("Works", "Totally Works")
    end
  end
end
