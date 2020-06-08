module Phaedra
  class Request < Rack::Request
    def query
      self.GET
    end

    def header
      @env.dup.transform_keys do |key|
        key.respond_to?(:downcase) ? key.downcase : key
      end
    end

    def body
      @request_body ||= "" + get_header(Rack::RACK_INPUT).read
    end
  end

  class RackApp
    def initialize(settings = {})
      @settings = {
        "root_dir" => Dir.pwd,
        "serverless_api_dir" => "api"
      }.merge(settings)
    end

    def call(env)
      full_api_path = File.expand_path(@settings["serverless_api_dir"], @settings["root_dir"])
      base_api_folder = File.basename(full_api_path)
      req = Request.new(env)
      res = Rack::Response.new

      api_folder = File.dirname(req.path).sub("/#{base_api_folder}", "")
      endpoint = File.basename(req.path)
      ruby_path = File.join(full_api_path, api_folder, "#{endpoint}.rb")
      if File.exist?(ruby_path)
        if Object.constants.include?(:PhaedraFunction)
          Object.send(:remove_const, :PhaedraFunction)
        end
        load ruby_path
        
        func = PhaedraFunction.new
        func.service(req, res)

        output = res.finish
        unless output[2].respond_to?(:each)
          output[2] = Array(output[2])
        end

        output
      else
        raise WEBrick::HTTPStatus::NotFound, "`#{req.path}' not found."
      end
    rescue WEBrick::HTTPStatus::Status => e
      [e.code, { "Content-Type" => "text/plain" }, [e.reason_phrase]]
    end
  end
end
