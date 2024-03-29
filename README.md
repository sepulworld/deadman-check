# Deadman Check

![CodeQL](https://github.com/sepulworld/deadman-check/workflows/CodeQL/badge.svg)
[![Gem Version](https://badge.fury.io/rb/deadman_check.svg)](http://badge.fury.io/rb/deadman_check)

A monitoring sidecar for Nomad periodic [jobs](https://www.nomadproject.io/docs/job-specification/periodic.html) that alerts if the periodic job isn't
running at the expected interval.


# Overview
1. [Requierments](#requirements)
2. [Monitoring Modes](#monitoringmodes)
3. [Alert Options](#alertoptions)
4. [Example Usage](#exampleusage)
5. [Alerting Setup](#alertingsetup)
6. [CLI Usage](#cliusage)
7. [Local System Installation Option](#localsysteminstallationoption)
8. [Run deadman-check via Docker Option](#rundeadmanviadockeroption)
9. [CLI Command Help](#clicommandhelp)
  1. [Usage for key_set command](#usageforkeysetcommand)
  2. [Usage for switch_monitor command](#usageforswitchmonitorcommand)
10. [Development](#development)
11. [Contributing](#contributing)
12. [License](#license)

## Requirements

* [Consul](https://www.consul.io/)


## Monitoring Modes

1. Run with the Nomad periodic job as an additional [task](https://www.nomadproject.io/docs/job-specification/task.html). In this mode deadman-check will leverage a Consul key store to evaluate task frequency requirements. It uses [Epoch time](https://en.wikipedia.org/wiki/Unix_time) to verify task is running within time frequency required.

2. Run as a stand alone process that can monitor a large grouping of jobs which are reporting time frequency values into a Consul key.


## Alert Options

* [Slack](https://slack.com/)
<img width="752" alt="screen shot 2017-03-26 at 3 29 28 pm" src="https://cloud.githubusercontent.com/assets/538171/24335811/2e57eee8-1239-11e7-9fff-c8a10d956f2e.png">

* [AWS SNS](https://aws.amazon.com/documentation/sns/) - Broadcasting alerts and/or triggering [AWS Lambda functions](https://docs.aws.amazon.com/sns/latest/dg/sns-lambda.html) to run code
<img width="903" alt="screen shot 2017-08-04 at 11 39 12 am" src="https://user-images.githubusercontent.com/538171/28982223-e576743c-7909-11e7-8e65-ebb0b4a76762.png">

## Example Usage

Let's say I have a Nomad periodic job that is set to run every 10 minutes. The Nomad configuration looks like this:

```hcl
job "SilverBulletPeriodic" {
  datacenters = ["dc1"]
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

To monitor the SilverBulletPeriodicProcess task let's add a deadmad-check task. The host input is the Consul endpoint required by deadman-check (In this case 10.0.0.10)

```hcl
job "SilverBulletPeriodic" {
  datacenters = ["dc1"]
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
          "10.0.0.10",
          "--port",
          "8500",
          "--key",
          "deadman/SilverBulletPeriodicProcess",
          "--frequency",
          "700"]
      }
      resources {
        cpu = 100
        memory = 256
      }
    }
  }
}
```
<img width="1215" alt="screen shot 2017-04-23 at 11 14 36 pm" src="https://cloud.githubusercontent.com/assets/538171/25324439/b65541d6-287a-11e7-9b6d-4e1c9565eed2.png">

The Consul key, deadman/SilverBulletPeriodicProcess, at 10.0.0.10 will be updated with
the Epoch time for each SilverBulletPeriodic job run. If the job hangs or fails to run
the job frequency calculation will be in an alerting state. 

Next we need a job that will run to monitor this key.

```hcl
job "DeadmanMonitoring" {
  datacenters = ["dc1"]
  type = "service"

  group "monitor" {
    task "DeadmanMonitorSilverBulletPeriodicProcess" {
      driver = "docker"
      config {
        image    = "sepulworld/deadman-check"
        command  = "switch_monitor"
        args     = [
          "--host",
          "10.0.0.10",
          "--port",
          "8500",
          "--key",
          "deadman/SilverBulletPeriodicProcess",
          "--alert-to-slack",
          "slackroom",
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

Monitor a Consul key that contains an Epoch time entry. Send a Slack message if Epoch age hits given frequency threshold

<img width="752" alt="screen shot 2017-03-26 at 3 29 28 pm" src="https://cloud.githubusercontent.com/assets/538171/24335811/2e57eee8-1239-11e7-9fff-c8a10d956f2e.png">

If you have multiple periodic jobs that need to be monitored then use the ```--key-path``` argument instead of ```--key```. Be sure to ```key_set``` all under the same Consul key path.

<img width="658" alt="screen shot 2017-04-23 at 11 17 29 pm" src="https://cloud.githubusercontent.com/assets/538171/25324510/14d6e7f0-287b-11e7-9c0d-733d69e1cc94.png">

To monitor the above you would just use the ```--key-path``` argument instead of ```--key``` and AWS SNS for alerting endpoint

```hcl
job "DeadmanMonitoring" {
  datacenters = ["dc1"]
  type = "service"

  group "monitor" {
    task "DeadmanMonitorSilverBulletPeriodicProcesses" {
      driver = "docker"
      config {
        image    = "sepulworld/deadman-check"
        command  = "switch_monitor"
        args     = [
          "--host",
          "10.0.0.1",
          "--port",
          "8500",
          "--key-path",
          "deadman/",
          "--alert-to-sns",
          "arn:aws:sns:us-east-1:123412345678:deadman-check",
          "--alert-to-sns-region",
          "us-east-1",
          "--daemon",
          "--daemon-sleep",
          "900"]
      }
      resources {
        cpu = 100
        memory = 256
      }
      env {
        AWS_ACCESS_KEY_ID = "YourAWSKEY"
        AWS_SECRET_ACCESS_KEY = "YourAWSSecret"
      }
    }
  }
}
```

## Alerting Setup

* Slack alerting requires a SLACK_API_TOKEN environment variable to be set (use [Slack Bot integration](https://my.slack.com/services/new/bot)) (optional)

* [AWS SNS](https://aws.amazon.com/documentation/sns/) alerting requires appropreiate AWS IAM access to target SNS topic. One of the following can be used for authentication. IAM policy access to publish to the topic will be required
  - ENV['AWS_ACCESS_KEY_ID'] and ENV['AWS_SECRET_ACCESS_KEY']
  - The shared credentials ini file at ~/.aws/credentials (more information)
  - From an [instance profile](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html) when running on EC2


# CLI Usage:

## Local System Installation Option 

```
gem install deadman_check
```

## Run deadman-check via Docker Option

```
$ alias deadman-check='\
  docker run \
    -it --rm --name=deadman-check \
    sepulworld/deadman-check'
```


## CLI Command Help 

```bash
$ deadman-check -h
  NAME:

    deadman-check

  DESCRIPTION:

    Monitor a Consul key or key-path that contains an EPOCH time entry and frequency. Send Slack message if EPOCH age is greater than given frequency

  COMMANDS:

    help           Display global or [command] help documentation
    key_set        Update a given Consul key with current EPOCH
    switch_monitor Target a Consul key to monitor

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

    key_set will set a consul key that contains the current epoch and time frequency that job should be running at, example key {"epoch":1493010437,"frequency":"300"}

  EXAMPLES:

    # Update a Consul key deadman/myservice, with current EPOCH time
    deadman-check key_set --host 127.0.0.1 --port 8500 --key deadman/myservice --frequency 300

  OPTIONS:

    --host HOST
        IP address or hostname of Consul system

    --port PORT
        port Consul is listening on

    --key KEY
        Consul key to report EPOCH time and frequency for service

    --frequency FREQUENCY
        Frequency at which this key should be updated in seconds

    --consul-token TOKEN
        Consul KV access token (optional)
```

### Usage for switch_monitor command

```bash
$ deadman-check switch_monitor -h

  NAME:

    switch_monitor

  SYNOPSIS:

    deadman-check switch_monitor [options]

  DESCRIPTION:

    switch_monitor will monitor either a given key which contains a services last epoch checkin and frequency, or a series of services that set keys
under a given key-path in Consul

  EXAMPLES:

    # Target a Consul key deadman/myservice, and this key has an EPOCH value to check looking to alert
    deadman-check switch_monitor --host 127.0.0.1 --port 8500 --key deadman/myservice --alert-to-slack my-slack-monitor-channel

    # Target a Consul key path deadman/, which contains 2 or more service keys to monitor, i.e. deadman/myservice1, deadman/myservice2,
deadmman/myservice3 all fall under the path deadman/
    deadman-check switch_monitor --host 127.0.0.1 --port 8500 --key-path deadman/ --alert-to-slack my-slack-monitor-channel

    # Target a Consul key path deadman/, alert to Amazon SNS, i.e. deadman/myservice1, deadman/myservice2, deadmman/myservice3 all fall under the path
deadman/
    deadman-check switch_monitor --host 127.0.0.1 --port 8500 --key-path deadman/ --alert-to-sns arn:aws:sns:*:123456789012:my_corporate_topic

  OPTIONS:

    --host HOST
        IP address or hostname of Consul system

    --port PORT
        port Consul is listening on

    --key-path KEYPATH
        Consul key path to monitor, performs a recursive key lookup at given path.

    --key KEY
        Consul key to monitor, provide this or --key-path if you have multiple keys in a given path.

    --alert-to-slack SLACKCHANNEL
        Slack channel to send alert, don't include the # tag in name

    --alert-to-sns SNSARN
        Amazon Web Services SNS arn to send alert, example arn arn:aws:sns:*:123456789012:my_corporate_topic

    --alert-to-sns-region AWSREGION
        Amazon Web Services region the SNS topic is in, defaults to us-west-2

    --daemon
        Run as a daemon, otherwise will run check just once

    --daemon-sleep SECONDS
        Set the number of seconds to sleep in between switch checks, default 300

    --consul-token TOKEN
        Consul KV access token (optional)
```

### Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sepulworld/deadman_check. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


### License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
