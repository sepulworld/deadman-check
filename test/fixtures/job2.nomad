job "SilverBulletPeriodic" {
  type = "batch"
  datacenters = ["dc1"]

  periodic {
    cron             = "*/1 * * * * *"
    prohibit_overlap = true
  }

  group "silverbullet" {
    task "DeadmanSetSilverBulletPeriodicProcess" {
      driver = "docker"
      config {
        image    = "sepulworld/deadman-check"
        command  = "key_set"
        args     = [
          "--host",
          "192.168.43.145",
          "--port",
          "6379",
          "--key",
          "deadman/SilverBulletPeriodicProcess"]
      }
      resources {
        cpu = 100
        memory = 256
      }
    }
  }
}
