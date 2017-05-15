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

为了能够初始化这个项目, 需要在合适的地方设置 Hutch 的 setup_proc 用于初始化 Hutch::Schedule

```ruby
Hutch::Config.setup_procs  << -> {
	Hutch::Schedule.connect(Hutch.broker)
}
```

提供了如下的功能支持:
1. 在 RabbitMQ 中自动创建了一个 <hutch>.schedule 的 topic exchange 用于专门转发需要延迟的 Message
2. 在 RabbitMQ 中自动创建了一个 <hutch>_schedule_queue 的 queue 带有:
   - dlx 到 <hutch> 的 topic exchange
   - 以及避免任务一直挤压的 30 天的 ttl

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/hutch-schedule. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

