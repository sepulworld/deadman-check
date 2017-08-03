require 'deadman_check/version'
require 'diplomat'

module DeadmanCheck
  class DeadmanCheckGlobal

    def get_epoch_time
      epoch_time_now = Time.now.to_i
      return epoch_time_now
    end

    def configure_diplomat(host, port)
      Diplomat.configure do |config|
        config.url = "http://#{host}:#{port}"
      end
    end
  end

  class DeadmanCheckSlackAuth
    Slack.configure do |config|
      config.token = ENV['SLACK_API_TOKEN']
    end
  end

  class DeadmanCheckSnsAuth
    attr_accessor :region_name

    # Default credentials are loaded automatically from the following locations:
    # 1. ENV['AWS_ACCESS_KEY_ID'] and ENV['AWS_SECRET_ACCESS_KEY']
    # 2. The shared credentials ini file at ~/.aws/credentials (more information)
    # 3. From an instance profile when running on EC2
    
    def initialize(region_name)
      @region_name = region_name
    end

    sns = Aws::SNS::Client.new(
      region_name: region_name
      )
  end
end
