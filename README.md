# Phaedra: Serverless Ruby Functions

Phaedra is a web microframework for writing serverless Ruby functions. They are isolated pieces of logic which respond to HTTP requests (GET, POST, etc.) and typically get mounted at a particular URL path. They can be tested locally and deployed to a supported serverless hosting platform or to any [Rack-compatible web server](https://github.com/rack/rack).

Serverless compatibility is presently focused on [Vercel](https://vercel.com) and [OpenFaaS](https://openfaas.com), but there are likely additional platforms we'll be adding support for in the future.

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

## Usage

Functions are single Ruby files which respond to a URL path (aka `/api/path/to/function`). The path is determined by the location of the file on the filesystem relative to the functions root (aka `api`). So, given a path of `./api/folder/run-me.rb`, the URL path would be `/api/folder/run-me`.

Functions are written as subclasses of `Phaedra::Base` using the name `PhaedraFunction`. The `params` argument is a Hash containing the parsed contents of the incoming query string, form data, or body JSON. The response object returned by your function is typically a Hash which will be transformed into JSON output automatically, but it can also be plain text.

Some platforms such as Vercel require the function class name to be `Handler`, so you can put that at the bottom of your file for full compatibility.

Here's a basic example:

```ruby
require "phaedra"

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
  after_action :do_stuff_after
  around_action :do_it_all_around

  def do_stuff_before
    # code
  end

  # do_stuff_after, etc.

  def get(params)
    # this will be run within the callback chain
  end
end
```

You can modify the `request` object in a `before_action` callback to perform setup tasks before the actions are executed, or you can modify `response` in a `after_action` to further process the response.

## Shared Code You Only Want to Run Once

You can use `require_relative` to load and execute shared Ruby code from another folder, say `lib`. This is particularly useful when setting up a database connection or performing expensive operations you only want to do once, rather than for every request.

```ruby
# api/run-it-once.rb

require "phaedra"
require_relative "../lib/shared_code"

class PhaedraFunction < Phaedra::Base
  def get(params)
    "Run it once! #{SharedCode.run_once}"
  end
end
```

```ruby
# lib/shared_code.rb
module SharedCode
  def self.run_once
    @one_time ||= Time.now
  end
end
```

Now each time you invoke the function at `/api/run-it-once`, the timestamp will never change until the next redeployment.

## Deployment

### Vercel

All you have to do is create a static site repo ([Bridgetown](https://www.bridgetownrb.com), Jekyll, Middleman, etc.) with an `api` folder and Vercel will automatically set up the serverless functions every time there's a new branch or production deployment. As mentioned above, you'll need to ensure you add `Handler = PhaedraFunction` to the bottom of each Ruby function.

### OpenFaaS

We recommend using OpenFaaS' [ruby-http template](https://github.com/openfaas-incubator/ruby-http). It boots up a Sinatra/WEBrick server and then passes all requests along to a Handler object.

In your OpenFaaS project's function folder (e.g., `testphaedra`), simply define `handler.rb` which will in turn load Phaedra's default Rack app:

```ruby
# testphaedra/handler.rb

require "phaedra"

class Handler
  def run(_body, env)
    status, headers, body = Phaedra::RackApp.new({
      "root_dir" => File.join(Dir.pwd, "function")
    }).call(env)

    # The OpenFaaS ruby-http return array is backwards from Rack :/
    [body.join(""), headers, status]
  end
end
```

Next, add a YAML file that lives alongside your function folder:

```yaml
# testphaedra.yml

version: 1.0
provider:
  name: openfaas
  gateway: http://127.0.0.1:8080
functions:
  testphaedra:
    lang: ruby-http
    handler: ./testphaedra
    image: yourdockerusername/testphaedra:latest
```

Now run `faas-cli up -f testphaedra.yml` to build and deploy the function. Given the Ruby function `testphaedra/api/run-me.rb`, you'd call it like so:

```sh
curl http://127.0.0.1:8080/function/testphaedra/api/run-me
```

In case you're wondering: yes, with Phaedra you can write multiple Ruby functions which will be accessible via different URL paths—all handled by a single OpenFaaS function. Of course it's possible set up multiple Phaedra projects and deploy them as separate OpenFaaS functions if you wish.

### Rack

Booting Phaedra up as Rack app is very simple. All you need to do is add a `config.ru` file alongside your `api` folder:

```ruby
require "phaedra"

run Phaedra::RackApp.new
```

Then run `rackup` in the terminal.

The settings (and their defaults) you can pass to the `new` method are as follows:

```ruby
{
  "root_dir" => Dir.pwd,
  "serverless_api_dir" => "api"
}
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

This method precludes any automatic routing by Phaedra, so it's discouraged unless you are using WEBrick within a larger setup that utilizes its own routing method. (Interestingly enough, that's how Vercel works under the hood.)

----

## Development

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/whitefusionhq/phaedra.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Phaedra project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/whitefusionhq/phaedra/blob/master/CODE_OF_CONDUCT.md).
