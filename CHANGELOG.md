# Change Log
All notable changes to this project will be documented in this file.

## [0.7.3] - 2020-04-16
### Fixed
- add #threshold Proc to support pass enqueue msg to lambada args 
- add check interval for flush Hutch::Worker.buffer_queue to RabbitMQ to avoid blocking for handling limited message

## [0.7.1] - 2020-04-16
### Fixed
- add threshold default {context, rate, interval} value
- fix monkey patch Hutch::Config.define_methods

## [0.7.0] - 2020-04-13
### Fixed
- Use monkey patch to support Conumser ratelimit through Hutch::Threshold
- Use monkey patch to expand Hutch::Config add more work pool relate configurations
- Upgrade Hutch to 1.0

## [0.6.1]  - 2018-05-23
### Fixed
- When message requeue merge the message headers properties

## [0.6.0] - 2018-04-17
### Fixed
- Reuse Hutch::Enqueue in HutchAdapter#dynamic_consumer

## [0.5.1] - 2018-04-15
### Fixed
- Fix dynamic_consumer name/inspect/to_s method issue
- Add delay time from seconds to days

## [0.4.3] - 2017-06-06
### Fixed
- Support #dynamic_consumer for HutchAdapter to adoption ActiveJob
- Provider correct #name for dynamic_consumer             

## [0.4.2] - 2017-05-23
### Fixed
- Reuse consumer when register ActiveJob queue to consumer


## [0.4.1] - 2017-05-22
### Fixed
- When register ActiveJob queue consumer, use job instance #queue_name not job class queue_name

## [0.4.0] - 2017-05-21
### Fixed
- Fix Hutch::ErrorsHandler::MaxRetry use Set#intersect? instead of Array#include? to 
calculate routing_key diff and aggregate message faild times.

