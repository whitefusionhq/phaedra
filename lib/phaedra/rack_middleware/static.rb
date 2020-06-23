module Phaedra
  module Middleware
    # Based on Rack::TryStatic middleware
    # https://github.com/rack/rack-contrib/blob/master/lib/rack/contrib/try_static.rb

    class Static
      def initialize(app, options)
        @app = app
        @try = ["", ".html", "index.html", "/index.html", *options[:try]]
        @static = Rack::Static.new(
          lambda { |_| [404, {}, []] },
          options)
      end

      def call(env)
        orig_path = env['PATH_INFO']
        found = nil
        @try.each do |path|
          resp = @static.call(env.merge!({'PATH_INFO' => orig_path + path}))
          break if !(403..405).include?(resp[0]) && found = resp
        end
        found or @app.call(env.merge!('PATH_INFO' => orig_path))
      end
    end
  end
end
