require "json"
require "webrick"
require "active_support/core_ext/hash/indifferent_access"
require "phaedra/concerns/callbacks_actionable"

module Phaedra
  class Base
    include CallbacksActionable

    # Used by WEBrick
    def self.get_instance(server, *options)
      self.new(server, *options)
    end

    # Context might be a WEBrick server, nil if coming from Rack
    def initialize(context = nil)
      @context = context
    end

    ######################
    # Override in subclass
    def get(params)
      raise WEBrick::HTTPStatus::NotFound, "`#{request.path}' not found."
    end

    def post(params)
      raise WEBrick::HTTPStatus::NotFound, "`#{request.path}' not found."
    end

    def put(params)
      raise WEBrick::HTTPStatus::NotFound, "`#{request.path}' not found."
    end

    def patch(params)
      put(params)
    end

    def delete(params)
      raise WEBrick::HTTPStatus::NotFound, "`#{request.path}' not found."
    end
    ######################

    def request; @req; end
    def response; @res; end

    def service(req, res)
      method_name = "do_" + req.request_method.gsub(/-/, "_")
      if respond_to?(method_name)
        __send__(method_name, req, res)
      else
        raise WEBrick::HTTPStatus::MethodNotAllowed,
              "unsupported method `#{req.request_method}'."
      end
    end

    def do_GET(req, res)
      @req = req
      @res = res

      set_initial_status

      result = run_callbacks :action do
        # WEBrick's query string handler with DELETE is funky
        params = if @req.request_method == "DELETE"
                   WEBrick::HTTPUtils::parse_query(@req.query_string)
                 else
                   @req.query
                 end

        @res.body = call_method_action(params)
      end

      return error_condition unless result
      
      complete_response
    end

    def do_POST(req, res)
      @req = req
      @res = res

      set_initial_status

      result = run_callbacks :action do
        params = if (@req.header["content-type"] || @req.header["content_type"]).to_s.include?("multipart/form-data")
          if @req.respond_to?(:params) # Rack
            @req.params
          else
            @req.query # WEBrick
          end
        else
          begin
            JSON.parse(@req.body)
          rescue JSON::ParserError, TypeError
            @req.body
          end
        end

        @res.body = call_method_action(params)
      end

      return error_condition unless result

      complete_response
    end

    alias_method :do_PUT, :do_POST
    alias_method :do_PATCH, :do_POST
    alias_method :do_DELETE, :do_GET

    protected

    def set_initial_status
      @res.status = 200
      @res["Content-Type"] = "application/json"
    end

    def call_method_action(params)
      params = params.is_a?(Hash) ? params.with_indifferent_access : params
      send(@req.request_method.downcase, params)
    end

    def complete_response
      if @res.body.is_a?(String) && !@res["Content-Type"].start_with?("text/")
        @res["Content-Type"] = "text/plain; charset=utf-8"
      elsif @res["Content-Type"] == "application/json"
        @res.body = @res.body.to_json
      end
    end

    def error_condition
      @res.status = 500
      @res["Content-Type"] = "text/plain"
      @res.body = "Internal Server Error (callback chain halted)"
    end
  end
end
