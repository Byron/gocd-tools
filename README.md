# GocdTools [![Build Status](https://travis-ci.org/Byron/gocd-tools.svg?branch=master)](https://travis-ci.org/Byron/gocd-tools)

This gem helps to maintain a [gocd][gocd] installation, and prevent it from becoming a snowflake when secure environment variables are involved.

Unfortunately, it's quite common to use the [GoCD][gocd] GUI of the production
instance to adjust the configuration. In a second step, the resulting configuration file is 
manually copied from the website, and placed under revision control, after manually sanitizing it.

All manual steps are error prone, even if we would ignore the fact that one is basically operating at an open heart.

Using the tools provided here, one can create a pipeline which supports local testing, with 
manual steps reduced to the bare minimum.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gocd-tools'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gocd-tools

## Usage from within Vagrant

TBD

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment. Run `bundle exec gocd-tools` to use the gem in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/gocd-tools. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

[gocd]: https://go.cd