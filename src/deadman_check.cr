require "./deadman_check/*"
require "commander"
require "smtp"
require "resp"

module DeadmanCheck
  cli = Commander::Command.new do |cmd|
    cmd.use = "deadman_check"
    cmd.long = "A script to check a given Redis key EPOCH for freshness. Good for
      monitoring cron jobs or batch jobs. Have the last step of the job post the
      EPOCH time to target Redis key. This script will monitor it for a given
      freshness value (difference in time now to posted EPOCH)"

    cmd.flags.add do |flag|
      flag.name = "redis"
      flag.short = "-r"
      flag.long = "--redis"
      flag.default = "127.0.0.1"
      flag.description = "The target redis host, default: 127.0.0.1"
    end

    cmd.flags.add do |flag|
      flag.name = "port"
      flag.short = "-p"
      flag.long = "--port"
      flag.default = 6379
      flag.description = "The Redis server port to connet to, default: 6379"
    end

    cmd.flags.add do |flag|
      flag.name = "key"
      flag.short = "-k"
      flag.long = "--key"
      flag.default = "unknown"
      flag.description = "The Redis key to monitor, key value must an EPOCH value"
    end

    cmd.flags.add do |flag|
      flag.name = "freshness"
      flag.short = "-f"
      flag.long = "--freshness"
      flag.default = "300"
      flag.description = "The EPOCH value found in the Redis key must be newer
        than this parameters value (in seconds), default: 300"
    end

    cmd.flags.add do |flag|
      flag.name = "email"
      flag.short = "-e"
      flag.long = "--email"
      flag.default = "youremail@yourdomain.net"
      flag.description = "The email address to send notifications"
    end
  end

  Commander.run(cli, ARGV)

  def check_redis_deadman_key(key)
  end

end
