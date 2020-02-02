require 'deadman_check/version'
require 'diplomat'

module DeadmanCheck
  class DeadmanCheckGlobal

    def get_epoch_time
      epoch_time_now = Time.now.to_i
      return epoch_time_now
    end

    def configure_diplomat(host, port, consul_token)
      Diplomat.configure do |config|
        config.url = "http://#{host}:#{port}"
        if consul_token != ""
            config.options = {headers: {"X-Consul-Token" => consul_token}}
        end
      end
    end
  end
end
