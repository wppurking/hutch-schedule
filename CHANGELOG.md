# Change Log
All notable changes to this project will be documented in this file.

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

