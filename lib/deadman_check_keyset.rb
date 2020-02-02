require 'deadman_check/version'
require 'deadman_check_global'
require 'diplomat'
require 'json'

module DeadmanCheck
  # KeySet Class
  class KeySet
    attr_accessor :host, :port, :key, :frequency, :consul_token

    def initialize(host, port, key, frequency, consul_token)
      @host = host
      @port = port
      @key  = key
      @frequency = frequency
      @consul_token = consul_token
    end

    def run_consul_key_update
      update_consul_key(@host, @port, @key, @frequency, @consul_token)
    end

    private
      def generate_json(epoch, frequency)
        consul_key = { :epoch => epoch, :frequency => frequency }
        consul_key.to_json
      end

      def update_consul_key(host, port, key, frequency, consul_token)
        DeadmanCheck::DeadmanCheckGlobal.new.configure_diplomat(host, port, consul_token)
        epoch_time_now = DeadmanCheck::DeadmanCheckGlobal.new.get_epoch_time
        Diplomat::Kv.put(key, "#{generate_json(epoch_time_now, frequency)}")
        puts "Consul key #{key} updated EPOCH to #{epoch_time_now}"
      end
  end
end
