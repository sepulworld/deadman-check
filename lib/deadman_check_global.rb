require 'deadman_check/version'
require 'diplomat'

module DeadmanCheck
  class DeadmanCheckGlobal

    def get_epoch_time
      epoch_time_now = Time.now.to_i
      return epoch_time_now
    end

    def configure_diplomat(host, port, token)
      Diplomat.configure do |config|
        config.url = "http://#{host}:#{port}"
        if defined? token
            config.options = {headers: {"X-Consul-Token" => token}}
        end
      end
    end
  end
end
