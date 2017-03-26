job "DeadmanMonitoring" {
  type = "service"
  datacenters = ["dc1"]

  group "monitor" {
    task "DeadmanMonitorSilverBulletPeriodicProcess" {
      driver = "docker"
      config {
        image    = "sepulworld/deadman-check"
        command  = "switch_monitor"
        args     = [
          "--host",
          "192.168.43.145",
          "--port",
          "8500",
          "--key",
          "deadman/SilverBulletPeriodicProcess",
          "--freshness",
          "80",
          "--alert-to",
          "random",
          "--daemon",
          "--daemon-sleep",
          "30"]
      }
      resources {
        cpu = 100
        memory = 500 
      }
      env {
        SLACK_API_TOKEN = "YourSlackKeyHere"
      }
    }
  }
}
