# Pundit::Resources

Pundit::Resources is a gem that makes [JSONAPI::Resources][jsonapi-resources] use [Pundit][pundit] authorization.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pundit-resources'
```

And then execute:

```sh
bundle
```

Or install it yourself as:

```sh
gem install pundit-resources
```

## Usage

Include `Pundit::ResourceController` in the resource controllers that should use Pundit.

You also need to define a `current_user` method on the controller.
The result of this method will be passed as the user parameter to the Pundit policies.

`Pundit::ResourceController` will raise an exception if authorization is not performed on any action, so you don't have to worry about anything slipping through the cracks.

```ruby
class ApplicationController < JSONAPI::ResourceController
  include Pundit::ResourceController

  protected

  def current_user
    User.find(params[:id])
  end
end
```

Also, include `Pundit::Resource` in the resources that should use Pundit:

```ruby
class ApplicationResource < JSONAPI::Resource
  include Pundit::Resource
end
```

Pundit::Resources does not use the `show?` action on Pundit policies.
Instead, it checks to see if the given resource is included in the Scope for that policy.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org][rubygems].

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

[jsonapi-resources]: https://github.com/cerebris/jsonapi-resources
[pundit]: https://github.com/elabs/pundit
[rubygems]: https://rubygems.org
