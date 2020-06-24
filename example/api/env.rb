require_relative "../phaedra/initializers"

class PhaedraFunction < Phaedra::Base
  def get(params)
    response["Content-Type"] = "text/html; charset=utf-8"
    <<~HTML
      <p>Hello! 😃</p>
      <p>Startup Time: #{Phaedra::Shared.the_time}</p>
      <p>Environment: #{Phaedra.environment}</p>
      <p>Current Time: #{Time.new}</p>
    HTML
  end
end

Handler = PhaedraFunction