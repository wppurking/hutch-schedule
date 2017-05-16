# Hutch::Schedule

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/hutch/schedule`. To experiment with that code, run `bin/console` for an interactive prompt.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hutch-schedule'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hutch-schedule

## Usage

Use the code below to initialize the Hutch::Schedule

```ruby
Hutch::Config.setup_procs  << -> {
	Hutch::Schedule.connect(Hutch.broker)
}
```

They will do something below:

1. Declear an topic exchange called <hutch>.schedule just for routing message to schedule_queue.
2. Declear an queue named <hutch>_schedule_queue and with some params:
  - Set `x-dead-letter-exchange: <hutch>`: let queue republish message to default <hutch> exchange.
  - Set `x-message-ttl: <30.days>`: to avoid the queue is to large, because there is no consumer with this queue.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/hutch-schedule. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

