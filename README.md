# RSpec API Blueprint

Autogenerate API documentation in API blueprint format from request specs.

You can find more about API blueprint at http://apiblueprint.org

## Installation

Add this line to your application's Gemfile:

    gem 'rspec_api_blueprint', require: false

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rspec_api_blueprint

## Usage

In your spec_helper.rb file add

    require 'rspec_api_blueprint'

Write tests using the following convention:

- Resource descriptions are named "Group" followed by the resource name. E.g. for model called Arena it would be `Group Arena`.
- Action descriptions are in the form of “VERB path”. For the show action of the arenas controller it would be `GET /v1/arenas/{id}`.

Example:

```ruby
describe 'Group Arena' do
  describe 'GET /v1/arenas/{id}' do
    it 'responds with the requested arena' do
      arena = create :arena, foursquare_id: '5104'
      get v1_arena_path(arena)

      response.status.should eq(200)
    end
  end
end
```

The output:

    # Group Arena

    ## GET /v1/arenas/{id}

    + Response 200 (application/json)

        {
          "arena": {
            "id": "4e9dbbc2-830b-41a9-b7db-9987735a0b2a",
            "name": "Clinton St. Baking Co. & Restaurant",
            "latitude": 40.721294,
            "longitude": -73.983994,
            "foursquare_id": "5104"
          }
        }

### Documentation

The generator can also take documentation from your source files and insert it into the resulting blueprint. It will be copied as-is from the comments, so you can use markdown, `+ Parameters`, and anything else that the [blueprint specification](https://github.com/apiaryio/api-blueprint/blob/master/API%20Blueprint%20Specification.md) supports.

Documentation for a resource is taken from a model file, and documentation for an action is taken from a controller file (see [configuration](#configuration)).

Example:

In `app/models/arena.rb`:

```ruby
# Arena represents a combat room.
#
# Attributes:
#
# - `name` - arena name
# - `foursquare_id`
class Arena < ActiveRecord::Base
  attr_accessible :name, :foursquare_id
end
```

In `app/controllers/arenas_controller.rb`:

```ruby
class ArenasController < ApplicationController

  # GET /v1/arenas/{id}
  # Fetch information about an arena.
  #
  # + Parameters
  #   + id (integer, `1`) ... arena id
  def show
    @arena = Arena.find(params[:id])
  end

end
```

Output:

    # Group Arena

    Arena represents a combat room.

    Attributes:

    - `name` - arena name
    - `foursquare_id`

    ## GET /v1/arenas/{id}
    Fetch information about an arena.

    + Parameters
      + id (integer, `1`) ... arena id

    + Response 200 (application/json)

        {
          "arena": {
            "id": "4e9dbbc2-830b-41a9-b7db-9987735a0b2a",
            "name": "Clinton St. Baking Co. & Restaurant",
            "latitude": 40.721294,
            "longitude": -73.983994,
            "foursquare_id": "5104"
          }
        }

### Configuration

You can customize paths and other behaviour in the RSpec config block in `spec_helper.rb`.

Example:

```ruby
RSpec.configure do |config|
  config.api_docs_output = './api_docs/generated'
end
```

Configuration options:

- `config.api_docs_output` sets the destination folder where the docs will be generated (default is `./api_docs`)

- `config.api_docs_controllers` folder where to look for action docs (default is `./app/controllers`).

  Can be passed a Proc to map resource name to file name:

  ```ruby
  config.api_docs_controllers = ->(resource) { "./app/controllers/#{resource}s_controller.rb" }
  ```

- `config.api_docs_models` folder where to look for model (resource) docs (default is `./app/models`).

  Can be passed a Proc to map resource name to file name:

  ```ruby
  config.api_docs_models = ->(resource) { "./app/models/#{resource}.rb" }
  ```

- `config.api_docs_whitelist` -- by default, docs for all examples (that is, defined by `it`, `specify`, `example` and all other [aliases](http://rubydoc.info/gems/rspec-core/RSpec/Core/ExampleGroup.alias_example_to)) will be generated.

  If you want to only generate docs for some examples, set `config.api_docs_whitelist = true` and then define examples as `it "...", :docs do ... end`. Examples defined with `:docs => false` will never be documented, regardless of the whitelist property.

  You can use an alias method `docs` as a shortcut for docs-enabled examples: `docs "..." do ... end`.

- If you want to ensure the order of requests in the generated docs, set `config.order = 'default'` (or run as `rspec --order default`).

## Caveats

- 401, 403 and 301 statuses are ignored since rspec produces a undesired output. TODO: Add option to choose ignored statuses.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

### Test

    $ cucumber

(in progress)
