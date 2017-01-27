#!/usr/bin/env perl

use 5.24.0;
use strict;
use warnings;

use JSON;
use IPC::Cmd 'run';

my $verbose            = $ENV{'MOJO_VERBOSE'} || 0;
my $config             = decode_json($ENV{'APP_CONFIG'}) || "Invalid configuration";
my $zbx_server         = $config->{'zabbix'}{'server'};
my $zbx_heartbeat_item = 'gzalertmon.timestamp';
my $zbx_sender         = '/usr/bin/zabbix_sender';

my $command = '';

while (1) {
  foreach my $graylog (@{$config->{'graylog'}}) {
    my $timestamp = time();
    my $zbx_host  = $graylog->{'hostname'};
  
    $command = [
      $zbx_sender,
      '-vvz', $zbx_server,
      '-s',   $zbx_host,
      '-k',   $zbx_heartbeat_item,
      '-o',   $timestamp
    ];

    run(command => $command, verbose => $verbose, timeout => 60);
  }

  sleep 60;
}
