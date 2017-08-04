require 'test_helper'

class DeadmanCheckTest < Minitest::Test

  @@standalone_key_response = "[
    {
        \"LockIndex\": \"0\",
        \"Key\": \"deadman/myservice1\",
        \"Flags\": \"0\",
        \"Value\": \"eyJlcG9jaCI6MTQ5MzAxMDQzNywiZnJlcXVlbmN5IjoiMzAwIn0=\",
        \"CreateIndex\": \"9\",
        \"ModifyIndex\": \"465\"
    }
  ]"

  @@recursive_key_response = "[
    {
        \"LockIndex\": \"0\",
        \"Key\": \"deadman/myservice\",
        \"Flags\": \"0\",
        \"Value\": \"eyJlcG9jaCI6MTQ5Mjk2NDU0NSwiZnJlcXVlbmN5IjoiMzAwIn0=\",
        \"CreateIndex\": \"8\",
        \"ModifyIndex\": \"10\"
    },
    {
        \"LockIndex\": \"0\",
        \"Key\": \"deadman/myservice2\",
        \"Flags\": \"0\",
        \"Value\": \"eyJlcG9jaCI6MTQ5Mjk2NTI5MiwiZnJlcXVlbmN5IjoiMzAwIn0=\",
        \"CreateIndex\": \"58\",
        \"ModifyIndex\": \"58\"
    },
    {
        \"LockIndex\": \"0\",
        \"Key\": \"deadman/myservice3\",
        \"Flags\": \"0\",
        \"Value\": \"eyJlcG9jaCI6MTQ5Mjk2NTMxMSwiZnJlcXVlbmN5IjoiMzAwIn0=\",
        \"CreateIndex\": \"61\",
        \"ModifyIndex\": \"61\"
    },
    {
        \"LockIndex\": \"0\",
        \"Key\": \"deadman/myservice4\",
        \"Flags\": \"0\",
        \"Value\": \"eyJlcG9jaCI6MTQ5Mjk2NTI5NywiZnJlcXVlbmN5IjoiMzAwIn0=\",
        \"CreateIndex\": \"59\",
        \"ModifyIndex\": \"59\"
    }
]"

  def test_that_it_has_a_version_number
    refute_nil ::DeadmanCheck::VERSION
  end

  def test_consul_key_update_slack
    stub_request(:put, "http://127.0.0.1:8500/v1/kv/test").
      with(body: "{\"epoch\":#{Time.now.to_i},\"frequency\":\"300\"}").
      to_return(status: 200, body: "", headers: {})
    key_set = DeadmanCheck::KeySet.new('127.0.0.1', '8500', 'test',
     '300')
    key_set.run_consul_key_update
  end

  def test_recursive_key_lookup_slack
    stub_request(:get, "http://127.0.0.1:8500/v1/kv/deadman/?recurse").
      to_return(status: 200, body: @@recursive_key_response, headers: {})
    stub_request(:post, "https://slack.com/api/chat.postMessage").
      to_return(status: 200, body: "{\"ok\":true}", headers: {})
    switch_monitor = DeadmanCheck::SwitchMonitor.new('127.0.0.1', '8500',
      'deadman/', 'monitoroom', nil, nil, true, '30')
    switch_monitor.run_check_once
  end

  def test_standalone_key_lookup_slack
    stub_request(:get, "http://127.0.0.1:8500/v1/kv/deadman/myservice1").
      to_return(status: 200, body: @@standalone_key_response, headers: {})
    stub_request(:post, "https://slack.com/api/chat.postMessage").
      to_return(status: 200, body: "{\"ok\":true}", headers: {})
    switch_monitor = DeadmanCheck::SwitchMonitor.new('127.0.0.1', '8500',
      'deadman/myservice1', 'monitoroom', nil, nil, false, '30')
    switch_monitor.run_check_once
  end
end
