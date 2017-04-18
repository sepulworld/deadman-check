require 'deadman_check/version'
require 'deadman_check_global'
require 'diplomat'
require 'slack-ruby-client'
require 'json'

module DeadmanCheck
  # Switch class
  class SwitchMonitor
    attr_accessor :host, :port, :key_path, :alert_to, :daemon_sleep

    def initialize(host, port, key_path, alert_to, daemon_sleep)
      @host = host
      @port = port
      @key_path = key_path
      @alert_to = alert_to
      @daemon_sleep = daemon_sleep.to_i
    end

    Slack.configure do |config|
      config.token = ENV['SLACK_API_TOKEN']
    end

    def _diff_epoch(current_epoch, recorded_epoch)
      epoch_difference = current_epoch - recorded_epoch
      return epoch_difference
    end

    def _get_recorded_epochs(host, port, key)
      DeadmanCheck::DeadmanCheckGlobal.new.configure_diplomat(host, port)
      recorded_epochs_json = Diplomat::Kv.get(key, recurse: true)
      return recorded_epochs_json
    end

    def _check_recorded_epochs(recorded_epochs_json, current_epoch)
      recorded_epochs_json.each do |recorded_service|
        recorded_service.each do |service, value|
          epoch_diff = _diff_epoch(value['epoch'], current_epoch)
          if epoch_diff > value['frequency']
            slack_alert(@alert_to, service, epoch_diff)
          end
        end
      end
    end

    def slack_alert(alert_to, key, epoch_diff)
      client = Slack::Web::Client.new
      client.chat_postMessage(channel: "\##{alert_to}", text: "Alert: Deadman Switch
        Triggered for #{key}, with #{epoch_diff} seconds since last run",
        username: 'deadman')
    end

    def run_check_once
      recorded_epochs = _get_recorded_epochs(@host, @port, @key_path).to_i
      current_epoch = DeadmanCheck::DeadmanCheckGlobal.new.get_epoch_time.to_i
      _check_recorded_epochs(recorded_epochs, current_epoch)
    end

    def run_check_daemon
      loop do
        run_check_once
        sleep(@daemon_sleep)
      end
    end

  end
end
