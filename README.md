# How to use

`bin/app.pl` listens for callbacks from graylog.
`bin/heartbeat.pl` should be run every minute to update the heartbeat item in zabbix.
`bin/discovery.pl` should be run every minute to add/remove graylog streams from zabbix.

A `config.yml` should be mounted inside the container, the default location is /app/config.yml. Pass `MOJO_CONFIGFILE=/some/dir/config.yml' to change this behaviour.

Pass `MOJO_VERBOSE=1` to show command execution details.

Pass `MOJO_MODE=production` to run in prod mode.
