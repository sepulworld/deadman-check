# DeadmanCheck

[![Build Status](https://travis-ci.org/sepulworld/deadman-check.svg)](https://travis-ci.org/sepulworld/deadman-check)
[![Gem Version](https://badge.fury.io/rb/deadman-check.svg)](http://badge.fury.io/rb/deadman-check)

Monitor a Redis key that contains an EPOCH time entry. Send email if EPOCH age hits given threshold

## Installation

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install deadman_check

## Usage

```bash
$ deadman-check -h
  NAME:

    deadman-check

  DESCRIPTION:

    Monitor a Redis key that contains an EPOCH time entry.
      Send email if EPOCH age hits given threshold

  COMMANDS:

    help           Display global or [command] help documentation
    key_set        Update a given Redis key with current EPOCH
    switch_monitor Target a Redis key to monitor

  GLOBAL OPTIONS:

    -h, --help
        Display help documentation

    -v, --version
        Display version information

    -t, --trace
        Display backtrace when an error occurs
```

### Usage for key_set command

```bash
$ deadman-check key_set -h

  NAME:

    key_set

  SYNOPSIS:

    deadman-check key_set [options]

  DESCRIPTION:



  EXAMPLES:

    # Update a Redis key deadman/myservice, with current EPOCH time
    deadman-check key_set --host 127.0.0.1 --port 6379 --key deadman/myservice

  OPTIONS:

    --host HOST
        IP address or hostname of Redis system

    --port PORT
        port Redis is listening on

    --key KEY
        Redis key to monitor
```

### Usage for switch_monitor command

```bash
$ deadman-check switch_monitor -h

  NAME:

    switch_monitor

  SYNOPSIS:

    deadman-check switch_monitor [options]

  DESCRIPTION:



  EXAMPLES:

    # Target a Redis key deadman/myservice, and this key has an EPOCH
     value to check looking to alert on 500 second or greater freshness
    deadman-check switch_monitor \
      --host 127.0.0.1 \
      --port 6379 \
      --key deadman/myservice \
      --freshness 500 \
      --alert-to ops@mycomany.tld \
      --alert-from ops-no-reply-email@mycomany.tld

  OPTIONS:

    --host HOST
        IP address or hostname of Redis system

    --port PORT
        port Redis is listening on

    --key KEY
        Redis key to monitor

    --freshness SECONDS
        The value in seconds to alert on when the recorded
            EPOCH value exceeds current EPOCH

    --alert-to EMAIL
        Email address to send alert to

    --alert-from EMAIL
        Email address to send from
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/deadman_check. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
