require 'deadman_check/version'
require 'deadman_check_global'
require 'redis'
require 'pony'

module DeadmanCheck
  # Switch class
  class SwitchMonitor
    attr_accessor :host, :port, :key, :freshness, :alert_to, :alert_from

    def initialize(host, port, key, freshness, alert_to, alert_from)
      @host = host
      @port = port
      @key  = key
      @freshness = freshness.to_i
      @alert_to = alert_to
      @alert_from = alert_from
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

    def email_alert(alert_to, alert_from, key, recorded_epoch, current_epoch,
      epoch_diff)
      Pony.mail(:to => alert_to, :from => alert_from,
        :subject => "Alert: Deadman Switch Triggered for #{key}",
        :body => "Alert: Deadman Switch Triggered for #{key}, with
          #{epoch_diff} seconds since last run")
    end

    def run_check
      recorded_epoch = _get_recorded_epoch(@host, @port, @key).to_i
      current_epoch = DeadmanCheck::DeadmanCheckGlobal.new.get_epoch_time.to_i
      epoch_diff = _diff_epoc(current_epoch, recorded_epoch)
      if epoch_diff > @freshness
        email_alert(@alert_to, @alert_from, @key,
        recorded_epoch, current_epoch, epoch_diff)
      end
    end

  end
end
