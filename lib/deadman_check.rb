require "deadman_check/version"

module DeadmanCheck
  Dir[File.dirname(__FILE__) + '/*.rb'].each do |file|
    require file
  end
end
