require 'deadman_check/version'
require 'deadman_check_global'
require 'diplomat'

module DeadmanCheck
  # KeySet Class
  class KeySet
    attr_accessor :host, :port, :key

    def initialize(host, port, key)
      @host = host
      @port = port
      @key  = key
    end

    def _configure_diplomat(host, port)
      Diplomat.configure do |config|
        config.url = "http://#{host}:#{port}"
      end
    end

    def _update_consul_key(host, port, key)
      DeadmanCheck::DeadmanCheckGlobal.new.configure_diplomat(host, port)
      epoch_time_now = DeadmanCheck::DeadmanCheckGlobal.new.get_epoch_time
      Diplomat::Kv.put(key, "#{epoch_time_now}")
      puts "Consul key #{key} updated EPOCH to #{epoch_time_now}"
    end

    def run_consul_key_update
      _update_consul_key(@host, @port, @key)
    end
  end
end
