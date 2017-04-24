require 'deadman_check/version'
require 'deadman_check_global'
require 'diplomat'
require 'slack-ruby-client'
require 'json'

module DeadmanCheck
  # Switch class
  class SwitchMonitor
    attr_accessor :host, :port, :target, :alert_to, :recurse, :daemon_sleep

    def initialize(host, port, target, alert_to, recurse, daemon_sleep)
      @host = host
      @port = port
      @target = target
      @alert_to = alert_to
      @recurse = recurse
      @daemon_sleep = daemon_sleep.to_i
    end

    Slack.configure do |config|
      config.token = ENV['SLACK_API_TOKEN']
    end

    def run_check_once
      recorded_epochs = get_recorded_epochs(@host, @port, @target, @recurse)
      current_epoch = DeadmanCheck::DeadmanCheckGlobal.new.get_epoch_time.to_i
      if @recurse
        check_recursive_recorded_epochs(recorded_epochs, current_epoch)
      else
        record = parse_recorded_epoch(recorded_epochs)
        check_recorded_epoch(record, current_epoch)
      end
    end

    def run_check_daemon
      loop do
        run_check_once(target, recurse)
        sleep(@daemon_sleep)
      end
    end

    private
      def diff_epoch(current_epoch, recorded_epoch)
        epoch_difference = current_epoch - recorded_epoch
        return epoch_difference
      end

      def get_recorded_epochs(host, port, target, recurse)
        DeadmanCheck::DeadmanCheckGlobal.new.configure_diplomat(host, port)
        recorded_epochs = Diplomat::Kv.get(target, recurse: recurse)
        return recorded_epochs
      end

      def parse_recorded_epoch(recorded_epochs)
        # {"epoch":1493000501,"frequency":"300"}
        value_json = JSON.parse(recorded_epochs)
        frequency = value_json["frequency"].to_i
        epoch = value_json["epoch"].to_i
        return epoch, frequency
      end

      def alert_if_epoch_greater_than_frequency(epoch_diff, target, frequency)
        if epoch_diff > frequency
          slack_alert(@alert_to, target, epoch_diff)
        end
      end

      def check_recorded_epoch(parse_recorded_epoch, current_epoch)
        recorded_epoch = parse_recorded_epoch[0].to_i
        frequency = parse_recorded_epoch[1].to_i
        epoch_diff = diff_epoch(current_epoch, recorded_epoch)
        alert_if_epoch_greater_than_frequency(epoch_diff, @target, frequency)
      end

      def check_recursive_recorded_epochs(recorded_epochs, current_epoch)
        recorded_epochs.each do |recorded_service|
          value_json = JSON.parse(recorded_service[:value])
          frequency = value_json["frequency"].to_i
          epoch = value_json["epoch"].to_i
          epoch_diff = diff_epoch(current_epoch, epoch)
          alert_if_epoch_greater_than_frequency(epoch_diff,
                                                recorded_service[:key],
                                                frequency)
        end
      end

      def slack_alert(alert_to, target, epoch_diff)
        client = Slack::Web::Client.new
        client.chat_postMessage(channel: "\##{alert_to}", text: "Alert: Deadman Switch
          Triggered for #{target}, with #{epoch_diff} seconds since last run",
          username: 'deadman')
      end
  end
end
