# Hutch::Schedule

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/hutch/schedule`. To experiment with that code, run `bin/console` for an interactive prompt.

See [hutch-schedule-demo](https://github.com/wppurking/hutch-schedule-demo) how to integration with rails.

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
Hutch.connect
Hutch::Schedule.connect
```

They will do something below:

1. Declear an topic exchange called `<hutch>.schedule` just for routing message to schedule_queue.
2. Declear an queue named `<hutch>_schedule_queue` and with some params:
  - Set `x-dead-letter-exchange: <hutch>`: let queue republish message to default <hutch> exchange.
  - Set `x-message-ttl: <30.days>`: to avoid the queue is to large, because there is no consumer with this queue.
3. If ActiveJob is loaded. it will use `ActiveJob::Base.descendants` to register all ActiveJob class to one-job-per-consumer to Hutch::Consumer 


### Error Retry
If you want use error retry, then:

1. Add `Hutch::ErrorHandlers::MaxRetry` to `Hutch::Config.error_handlers` like below
```ruby
Hutch::Config.error_handlers << Hutch::ErrorHandlers::MaxRetry.new
```

2. Let `Hutch::Consumer` to include `Hutch::Enqueue` and setup `attempts`
```ruby
class PlanConsumer
  include Hutch::Consumer
  include Hutch::Enqueue
  
  attempts 3
  consume 'abc.plan'
end
```

Error retry will use ActiveJob `exponentially_longer` algorithm `(executes**4) + 2` seconds


## Rails

### Work with Hutch it`s self
Add an `hutch.rb` to `conf/initializers`:
```ruby
# reuse Hutch config.yaml file
Hutch::Config.load_from_file(Rails.root.join('config', 'config.yaml'))
# replace error_handlers with Hutch::ErrorHandlers::MaxRetry
Hutch::Config.error_handlers = [Hutch::ErrorHandlers::MaxRetry.new]
# Init Hutch
Hutch.connect
# Init Hutch::Schedule
Hutch::Schedule.connect
```

Then you can enqueue message in Rails console like below:
```ruby
PlanConsumer.enqueue(a: 1)
# or schedule message
PlanConsumer.enqueue_in(5.seconds, a: 1)
```

### Work with ActiveJob
```ruby
class EmailJob < ApplicationJob
  queue_as :email
  
  retry_on StandardError, wait: :exponentially_longer
  
  def perform(user_id)
    user = User.find(user_id)
    user.send_email
  end
end

# in rails console, you can
EmailJob.perform_later(user.id)
# or
EmailJob.set(wait: 5.seconds).perform_later(user.id)
```

## Development

After checking out the repo, run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wppurking/hutch-schedule. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

