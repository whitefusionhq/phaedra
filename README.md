# Phaedra: Serverless Ruby Functions

_NOTE: not yet released! Check back in June 2020!_

Phaedra is a REST microframework based on WEBrick which lets you write serverless Ruby functions. These can be tested locally and deployed to a serverless hosting platform such as [Vercel](https://vercel.com).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'phaedra'
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

Functions are written as subclasses of `Phaedra::Base` using the name `Handler`. The `params` argument is a Hash containing the parsed contents of the incoming query string or request body JSON. The response object returned by your function is typically a Hash which will be transformed into JSON output automatically.

Here's a basic example:

```ruby
require "phaedra"

class Handler < Phaedra::Base
  def get(params)
    {
      text: "I am a response!",
      equals: params[:left].to_i + params[:right].to_i
    }
  end
end
```

Your function can support `get`, `post`, `put`, `patch`, and `delete` methods which map to the corresponding HTTP verbs.

Each method is provided access to `request` and `response` objects which are instantiated by WEBrick.

Functions also support `action` callbacks:

```ruby
class Handler < Phaedra::Base
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

## Development

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/whitefusionhq/phaedra.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Phaedra project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/whitefusionhq/phaedra/blob/master/CODE_OF_CONDUCT.md).
