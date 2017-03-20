# deadman_check

Monitor a Redis key that contains an EPOCH time entry. Send email if EPOCH age hits given threshold

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  deadman_check:
    github: sepulworld/deadman_check
  smtp:
    github: raydf/smtp.cr
  commander:
    github: mrrooijen/commander
    version: ~> 0.3.3
  slack:
    github: DougEverly/slack.cr
    github: soveran/resp-crystal
    branch: ~> v0.3.0
```

## Usage

```crystal
require "deadman_check"
```

Install on a system PATH
deadman_check -h localhost:8500 -k key_to_check -t 300 

-h: consul host, including port
-k: consul key to check
-t: time difference from current EPOCH to alert againts

## Development

TODO: Write development instructions here

## Contributing

1. Fork it ( https://github.com/[your-github-name]/deadman_check/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [[your-github-name]](https://github.com/[your-github-name]) zane - creator, maintainer
