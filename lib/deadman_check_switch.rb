require 'deadman_check/version'
require 'deadman_check_global'
require 'redis'
require 'slack-ruby-client'

module DeadmanCheck
  # Switch class
  class SwitchMonitor
    attr_accessor :host, :port, :key, :freshness, :alert_to, :daemon_sleep

    def initialize(host, port, key, freshness, alert_to, daemon_sleep)
      @host = host
      @port = port
      @key  = key
      @freshness = freshness.to_i
      @alert_to = alert_to
      @daemon_sleep = daemon_sleep.to_i
    end

    Slack.configure do |config|
      config.token = ENV['SLACK_API_TOKEN']
    end

    def _diff_epoc(current_epoch, recorded_epoch)
      epoch_difference = current_epoch - recorded_epoch
      return epoch_difference
    end

    def _get_recorded_epoch(host, port, key)
      redis = Redis.new(:host => host, :port => port)
      recorded_epoch = redis.get(key)
      return recorded_epoch
    end

    def slack_alert(alert_to, key, epoch_diff)
      client = Slack::Web::Client.new
      client.chat_postMessage(channel: "\##{alert_to}", text: "Alert: Deadman Switch
        Triggered for #{key}, with #{epoch_diff} seconds since last run",
        username: 'deadman')
    end

    def run_check_once
      recorded_epoch = _get_recorded_epoch(@host, @port, @key).to_i
      current_epoch = DeadmanCheck::DeadmanCheckGlobal.new.get_epoch_time.to_i
      epoch_diff = _diff_epoc(current_epoch, recorded_epoch)
      if epoch_diff > @freshness
        slack_alert(@alert_to, @key, epoch_diff)
      end
    end

    def run_check_daemon
      loop do
        run_check_once
        sleep(@daemon_sleep)
      end
    end

  end
end
