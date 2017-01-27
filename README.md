## graylog-zabbix-alert-monitor

This application bridges the gap between graylog and zabbix. Its goal is to create and update items in zabbix based on alerts in graylog. There is no data going from zabbix to graylog.

### How to use

* `bin/app.pl` listens for callbacks from graylog
* `bin/heartbeat.pl` runs approx. every minute to update the heartbeat item in zabbix
* `bin/discovery.pl` runs approx. every minute to add/remove graylog streams in zabbix

Configuration is passed by setting the `APP_CONFIG` environment variable to a valid JSON-object. You can find an example inside this repository.

Pass `MOJO_VERBOSE=1` to show command execution details.

### How to build

Simply type `make`.
