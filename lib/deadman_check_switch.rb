require 'deadman_check/version'
require 'deadman_check_global'
require 'redis'
require 'pony'

module DeadmanCheck
  # Switch class
  class SwitchMonitor
    attr_accessor :host, :port, :key, :freshness, :alert_to, :alert_from

    def _diff_epoc(current_epoch, recorded_epoch)
      epoch_difference = current_epoch - recorded_epoch
      return epoch_difference.to_i
    end

    def _get_recorded_epoch(host, port, key)
      redis = Redis.new(:host => host, :port => port)
      recorded_epoch = redis.get(key)
      return recorded_epoch
    end

    def email_alert(alert_to, alert_from, key, recorded_epoch, current_epoch)
      Pony.mail(:to => alert_to, :from => alert_from,
        :subject => "Alert: Deadman Switch Triggered for #{key}",
        :body => "Alert: Deadman Switch Triggered for #{key}, with
          #{epoch_diff} seconds since last run")
    end

    def run_check(freshness)
      recorded_epoch = _get_recorded_epoch(host, port, key)
      current_epoch = DeadmanCheck.DeadmanCheckGlobal.get_epoch_time
      epoch_diff = _diff_epoc(current_epoch, recorded_epoch)
      if epoch_diff > freshness
        email_alert(alert_to, alert_from, key, recorded_epoch, current_epoch)
      end
    end
    
  end
end
