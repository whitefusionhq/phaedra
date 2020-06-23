module Phaedra
  module Middleware
    class NotFound
      def initialize(app, path, content_type = 'text/html; charset=utf-8')
        @app = app
        @content = File.read(path)
        @length = @content.bytesize.to_s
        @content_type = content_type
      end

      def call(env)
        response = @app.call(env)
        if response[0] == 404
          [404, {'Content-Type' => @content_type, 'Content-Length' => @length}, [@content]]
        else
          response
        end
      end
    end
  end
end
