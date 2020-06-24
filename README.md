# Phaedra: Serverless Ruby Functions

Phaedra is a web microframework for writing serverless Ruby functions. They are isolated pieces of logic which respond to HTTP requests (GET, POST, etc.) and typically get mounted at a particular URL path. They can be tested locally and deployed to a supported serverless hosting platform, using a container via Docker & Docker Compose, or to any [Rack-compatible web server](https://github.com/rack/rack).

Phaedra is well-suited for building an API layer which you attach to a static site (aka [the Jamstack](https://www.bridgetownrb.com/docs/jamstack)) to provide dynamic functionality accessible any time after the static site loads in the browser.

Serverless compatibility is presently focused on [Vercel](https://vercel.com) and [OpenFaaS](https://openfaas.com), but there are likely additional platforms we'll be adding support for in the future.

For swift deployment via Docker, we recommend [Fly.io](https://fly.io).

(P.S. Wondering how you can deploy a static site on [Netlify](https://www.netlify.com) and still use a Ruby API? Scroll down for a suggested approach!)

## Installation

Add this line to your application's Gemfile:

```ruby
gem "phaedra"
```

And then execute:

```sh
$ bundle
```

Or install it yourself as:

```sh
$ gem install phaedra
```

## Examples

[Here's an example](https://github.com/whitefusionhq/phaedra/tree/master/example) of what the structure of a typical Phaedra app looks like. It includes `config.ru` for booting it up as a Rack app using Puma, as well as a `Dockerfile` and `docker-compose.yml` so you can run the app containerized in virtually any development or production hosting environment.

[Here's a demo](https://phaedra-demo.whitefusion.design/api/env) of one of the functions. [And another one.](https://phaedra-demo.whitefusion.design/api/params?search=Waiting%20for%20Guffman)

## Usage

Functions are single Ruby files which respond to a URL path (aka `/api/path/to/function`). The path is determined by the location of the file on the filesystem relative to the functions root (aka `api`). So, given a path of `./api/folder/run-me.rb`, the URL path would be `/api/folder/run-me`.

Functions are written as subclasses of `Phaedra::Base` using the name `PhaedraFunction`. The `params` argument is a Hash containing the parsed contents of the incoming query string, form data, or body JSON. The response object returned by your function is typically a Hash which will be transformed into JSON output automatically, but it can also be plain text.

Code to be run once upon function initialization and shared between multiple functions should be placed in the `phaedra/initializers.rb` file (see more on that below).

Some platforms such as Vercel require the function class name to be `Handler`, so you can put that at the bottom of your file for full compatibility.

Here's a basic example:

```ruby
require_relative "../phaedra/initializers"

class PhaedraFunction < Phaedra::Base
  def get(params)
    {
      text: "I am a response!",
      equals: params[:left].to_i + params[:right].to_i
    }
  end
end

Handler = PhaedraFunction
```

Your function can support `get`, `post`, `put`, `patch`, and `delete` methods which map to the corresponding HTTP verbs.

Each method is provided access to `request` and `response` objects. If your function was directly instantiated by WEBrick, those will be `WEBrick::HTTPRequest` and `WEBrick::HTTPResponse` respectively. If your function was instantiated by Rack, those will be `Phaedra::Request` (a thin wrapper around `Rack::Request`) and `Rack::Response` respectively.

### Callbacks

Functions can define `action` callbacks:

```ruby
class PhaedraFunction < Phaedra::Base
  before_action :do_stuff_before
  after_action do
    # process response object further...
  end
  around_action :do_it_all_around

  def do_stuff_before
    # process request object before action handler...
  end

  def do_it_all_around
    # run code before
    yield
    # run code after
  end

  def get(params)
    # this will be run within the entire callback chain
  end
end
```

You can modify the `request` object in a `before_action` callback to perform setup tasks before the actions are executed, or you can modify `response` in a `after_action` to further process the response.

### Shared Code You Only Want to Run Once

Phaedra provides a default location to place shared modules and code that should be run once upon first deployment of your functions. This is particularly useful when setting up a database connection or performing expensive operations you only want to do once, rather than for every request.

Here's an example of how that works:

```ruby
# api/run-it-once.rb

require_relative "../phaedra/initializers"

class PhaedraFunction < Phaedra::Base
  def get(params)
    "Run it once! #{Phaedra::Shared.run_once} / #{Time.now}"
  end
end
```

```ruby
# phaedra/initializers.rb

module Phaedra
  module Shared
    Initializers.register self do
      run_once
    end

    def self.run_once
      @only_once ||= Time.now
    end
  end
end
```

Now each time you invoke the function at `/api/run-it-once`, the timestamp will never change until the next redeployment.

**NOTE:** When running in a Rack-based configuration (see below), Ruby's `load` method is invoked for every request to any Phaedra function. This means Ruby has to parse and compile the code in your function each time. For small functions this happens extremely quickly, but if you find yourself writing a large function and seeing some performance slowdowns, consider extracting most of the function code to additional Ruby files and using the `require_relative` technique as mentioned above. The Ruby code in those required files will only be compiled once and all classes/modules/etc. will be saved in memory until the next redeployment.

## Environment

You can set the environment of your Phaedra app using the `PHAEDRA_ENV` environment variable. That is then available via the `Phaedra.environment` method. By default, the value is `:development`.

```ruby
# ENV["PHAEDRA_ENV"] == "production"

Phaedra.environment == :production  # true
```

## Deployment

### Vercel

All you have to do is create a static site repo ([Bridgetown](https://www.bridgetownrb.com), Jekyll, Middleman, etc.) with an `api` folder and Vercel will automatically set up the serverless functions every time there's a new branch or production deployment. As mentioned above, you'll need to ensure you add `Handler = PhaedraFunction` to the bottom of each Ruby function.

### OpenFaaS

We recommend using OpenFaaS' dockerfile template so you can define your own `Dockerfile` to book Rack + Phaedra using the Puma web server. This also allows you to customize the Docker image configuration to install and configure other tools as necessary.

First make sure you've added Puma to your Gemfile:

```
gem "puma"
```

Then make sure you've pulled down the OpenFaaS template:

```sh
faas-cli template store pull dockerfile
```

Then add a `Dockerfile` to your OpenFaaS project's function folder (e.g., `testphaedra`):

```dockerfile
# testphaedra/Dockerfile

FROM openfaas/of-watchdog:0.7.7 as watchdog

FROM ruby:2.6.6-slim-stretch

COPY --from=watchdog /fwatchdog /usr/bin/fwatchdog
RUN chmod +x /usr/bin/fwatchdog

ARG ADDITIONAL_PACKAGE
RUN apt-get update \
  && apt-get install -qy --no-install-recommends build-essential ${ADDITIONAL_PACKAGE}

WORKDIR /home/app

# Use cache layer for Gemfile
COPY Gemfile   	.
RUN bundle install
RUN gem install puma -N

# Copy over the rest
COPY    .   .

# Create a non-root user
RUN addgroup --system app \
    && adduser --system --ingroup app app
RUN chown app:app -R /home/app
USER app

# Run Puma as the server process
ENV fprocess="puma -p 5000"

EXPOSE 8080

HEALTHCHECK --interval=2s CMD [ -e /tmp/.lock ] || exit 1

ENV upstream_url="http://127.0.0.1:5000"
ENV mode="http"

CMD ["fwatchdog"]
```

Next add the `config.ru` file to boot Rack:

```ruby
# testphaedra/config.ru

require "phaedra/rack_app"

run Phaedra::RackApp.new
```

Finally, add a YAML file that lives alongside your function folder:

```yaml
# testphaedra.yml

version: 1.0
provider:
  name: openfaas
  gateway: http://127.0.0.1:8080
functions:
  testphaedra:
    lang: dockerfile
    handler: ./testphaedra
    image: yourdockerusername/testphaedra:latest
```

(Replace `yourdockerusername` with your [Docker Hub](https://hub.docker.com) username.)

Now run `faas-cli up -f testphaedra.yml` to build and deploy the function. Given the Ruby function `testphaedra/api/run-me.rb`, you'd call it like so:

```sh
curl http://127.0.0.1:8080/function/testphaedra/api/run-me
```

In case you're wondering: yes, with Phaedra you can write multiple Ruby functions which will be accessible via different URL paths—all handled by a single OpenFaaS function. Of course it's possible set up multiple Phaedra projects and deploy them as separate OpenFaaS functions if you wish.

### Rack

Booting Phaedra up as Rack app is very simple. All you need to do is add a `config.ru` file alongside your `api` folder:

```ruby
require "phaedra/rack_app"

run Phaedra::RackApp.new
```

Then run `rackup` in the terminal, or use another Rack-compatible server like Puma or Passenger.

The settings (and their defaults) you can pass to the `new` method are as follows:

```ruby
{
  "root_dir" => Dir.pwd,
  "serverless_api_dir" => "api"
}
```

Wondering if you can deploy a static site with an `api` folder via Nginx + Passenger? Yes, you can! Just configure your `my_site.conf` file like so:

```nginxconf
server {
    listen 80;
    server_name www.domain.com;

    # Tell Nginx and Passenger where your site destination folder is
    root /home/me/my_site/output;

    # Turn on Passenger
    location /api {
      passenger_enabled on;
      passenger_ruby /usr/local/rvm/gems/ruby-2.6.6@mysite/wrappers/ruby;
    }
}
```

Change the `server_name`, `root`, and `passenger_ruby` paths to your particular setup and you'll be good to go. (If you run into any errors, double-check there's a `config.ru` in the parent folder of your site destination folder.)

### Docker

[In the example app provided](https://github.com/whitefusionhq/phaedra/tree/master/example), there is a `config.ru` file for booting it up as a Rack app using Puma. The `Dockerfile` and `docker-compose.yml` files allow you to easily build and deploy the app at port 8080 (but that can easily be changed). Using the Docker Compose commands:

```sh
# Build (if necessary) and deploy:
docker-compose up

# Get information on the running container:
docker-compose ps

# Inspect the output logs:
docker-compose logs

# Exit the running container:
docker-compose down

# If you make changes to the code and need to rebuild:
docker-compose up --build
```

#### Fly.io

Deploying your Phaedra app's Docker container via [Fly.io](https://fly.io) couldn't be easier. Simply create a new app and deploy using Fly.io's command line utility:

```sh
# Create the new app using your Fly.io account:
flyctl apps create

# Deploy using the Dockerfile:
flyctl deploy

# Print out the URL and other info on your new app:
flyctl info

# Change the Phaedra app environment:
flyctl secrets set PHAEDRA_ENV=production
```

### WEBrick

Integrating Phaedra into a WEBrick server is pretty straightforward. Given a `server` object, it can be accomplished thusly:

```ruby
full_api_path = File.expand_path("api", Dir.pwd)
base_api_folder = File.basename(full_api_path)

server.mount_proc "/#{base_api_folder}" do |req, res|
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
  else
    raise HTTPStatus::NotFound, "`#{req.path}' not found."
  end
end
```

You also have the option of loading and mounting `Handler` directly to the server:

```ruby
load File.join(Dir.pwd, "api", "func.rb")
@server.mount '/path', Handler
```

This method precludes any automatic routing by Phaedra, so it's discouraged unless you are using WEBrick within a larger setup that utilizes its own routing method. (Interestingly enough, [that's how Vercel works under the hood](https://github.com/vercel/vercel/blob/master/packages/now-ruby/now_init.rb).)

## Connecting a Static Site on Netlify to a Phaedra API

[Netlify](https://www.netlify.com) is a popular hosting solution for Jamstack (static) sites, but its serverless functions feature doesn't support Ruby. However, using proxy rewrites, you can deploy the static site part of your repository to Netlify and set the `/api` endpoint to route requests to your Phaedra app on the fly (hosted elsewhere).

For example, if your Phaedra app is hosted on Fly.io (see above), you'll want Netlify's CDN to proxy all requests to `/api/*` to that app's URL. We can accomplish that by adding a `_redirects` file to the static site's source folder (for Bridgetown sites, that's `src`):

```
/api/*  https://super-awesome-phaedra-api.fly.dev/api/:splat  200
```

Once that deploys, you can go to your Netlify site URL, append `/api/whatever`, and under-the-hood that will connect to `https://super-awesome-phaedra-api.fly.dev/api/whatever` in a completely transparent manner.

If you want to change the proxy URL for different contexts (staging vs. production, etc.), you can follow Netlify's "[Separate _redirects files for separate contexts or branches](https://community.netlify.com/t/support-guide-making-redirects-work-for-you-troubleshooting-and-debugging/13433)" instructions here.

----

## Development

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/whitefusionhq/phaedra.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Phaedra project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/whitefusionhq/phaedra/blob/master/CODE_OF_CONDUCT.md).
