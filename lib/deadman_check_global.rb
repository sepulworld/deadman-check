require 'deadman_check/version'

module DeadmanCheck
  class DeadmanCheckGlobal
    def get_epoch_time
      epoch_time_now = Time.now.to_i
      return epoch_time_now
    end
  end
end
