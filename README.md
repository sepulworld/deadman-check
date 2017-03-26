# DeadmanCheck

[![Build Status](https://travis-ci.org/sepulworld/deadman-check.svg)](https://travis-ci.org/sepulworld/deadman_check)
[![Gem Version](https://badge.fury.io/rb/deadman-check.svg)](http://badge.fury.io/rb/deadman_check)

A monitoring companion for Nomad periodic jobs that alerts if periodic jobs are
not processing as expected. The deadman-check has 2 modes, one to run with the
Nomad periodic job as an additional [task](https://www.nomadproject.io/docs/job-specification/task.html) to update a key in Redis with current EPOCH time. The other mode is of deadman-check
is intended to run as a separate process that will monitor the Redis key's EPOCH
time value and alert if that value fails to meet a time 'freshness' threshold that
is expected for that job.

* requires a Redis instance

## Example Usage

Let's say I have a Nomad periodic job that is set to run every 10 minutes. The Nomad configuration looks like this:

```hcl
job "SilverBulletPeriodic" {
  type = "batch"

  periodic {
    cron             = "*/10 * * * * *"
    prohibit_overlap = true
  }

  group "utility" {
    task "SilverBulletPeriodicProcess" {
      driver = "docker"
      config {
        image    = "silverbullet:build_1"
        work_dir = "/utility/silverbullet"
        command  = "blaster"
      }
      resources {
        cpu = 100
        memory = 500
      }
    }
  }
}
```

To monitor the SilverBulletPeriodicProcess task let's add a deadmad-check task to
run post updates to a Redis endpoint (10.0.0.1 for this example)

```hcl
job "SilverBulletPeriodic" {
  type = "batch"

  periodic {
    cron             = "*/10 * * * * *"
    prohibit_overlap = true
  }

  group "silverbullet" {
    task "SilverBulletPeriodicProcess" {
      driver = "docker"
      config {
        image    = "silverbullet:build_1"
        work_dir = "/utility/silverbullet"
        command  = "blaster"
      }
      resources {
        cpu = 100
        memory = 500
      }
    }
    task "DeadmanSetSilverBulletPeriodicProcess" {
      driver = "docker"
      config {
        image    = "sepulworld/deadman-check"
        command  = "key_set"
        args     = [
          "--host",
          "10.0.0.1",
          "--port",
          "6379",
          "--key",
          "deadman/SilverBulletPeriodicProcess"]
      }
      resources {
        cpu = 100
        memory = 256
      }
    }
  }
}
```

Now the key, deadman/SilverBulletPeriodicProcess, in redis1.mydomain.net will be updated with
the EPOCH time for each SilverBulletPeriodic job run. If the job hangs or fails to run
we will know via the EPOCH time entry going stale.

Next we need a job that will run to monitor this key.

```hcl
job "DeadmanMonitoring" {
  type = "service"

  group "monitor" {
    task "DeadmanMonitorSilverBulletPeriodicProcess" {
      driver = "docker"
      config {
        image    = "sepulworld/deadman-check"
        command  = "switch_monitor"
        args     = [
          "--host",
          "10.0.0.1",
          "--port",
          "6379",
          "--key",
          "deadman/SilverBulletPeriodicProcess",
          "--freshness",
          "800",
          "--alert-to",
          "#slackroom",
          "--daemon",
          "--daemon-sleep",
          "900"]
      }
      resources {
        cpu = 100
        memory = 256
      }
      env {
        SLACK_API_TOKEN = "YourSlackApiToken"
      }
    }
  }
}
```

Monitor a Redis key that contains an EPOCH time entry. Send a Slack message if EPOCH age hits given threshold

## Local system installation

execute:

    $ bundle install
    $ gem install deadman_check

## Install and run deadman-check from Docker

```
# Optional: If you don't pull explicitly, `docker run` will do it for you
$ docker pull sepulworld/deadman-check

$ alias deadman-check='\
  docker run \
    -it --rm --name=deadman-check \
    sepulworld/deadman-check'
```

(Depending on how your system is set up, you might have to add sudo in front of the above docker commands or add your user to the docker group).

If you don't do the docker pull, the first time you run deadman-check, the docker run command will automatically pull the sepulworld/deadman-check image on the Docker Hub. Subsequent runs will use a locally cached copy of the image and will not have to download anything.

## Usage via Local System Install

```bash
$ deadman-check -h
  NAME:

    deadman-check

  DESCRIPTION:

    Monitor a Redis key that contains an EPOCH time entry.
      Send a Slack message if EPOCH age hits given threshold

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
      --alert-to #slackroom

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

    --alert-to SLACKROOM
        Slackroom to alert to

    --daemon
        Run as a daemon, otherwise will run check just once

    --daemon-sleep SECONDS
        Set the number of seconds to sleep in between switch checks, default 300
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/deadman_check. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
