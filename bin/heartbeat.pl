#!/usr/bin/env perl

use 5.24.0;
use strict;
use warnings;

use YAML::Tiny;
use IPC::Cmd 'run';

my $verbose            = $ENV{'MOJO_VERBOSE'}    || 0;
my $configfile         = $ENV{'MOJO_CONFIGFILE'} || './config.yml';
my $config             = YAML::Tiny->read($configfile)->[0] || die "Can't read '$configfile': $!";
my $zbx_server         = $config->{'zabbix'}{'server'};
my $zbx_heartbeat_item = 'gzalertmon.timestamp';
my $zbx_sender         = '/usr/bin/zabbix_sender';
my $timestamp          = time();

my $command = '';

foreach my $graylog (@{$config->{'graylog'}}) {
  my $zbx_host = $graylog->{'hostname'};

  $command = [
    $zbx_sender,
    '-vvz', $zbx_server,
    '-s',   $zbx_host,
    '-k',   $zbx_heartbeat_item,
    '-o',   $timestamp
  ];

  run(command => $command, verbose => $verbose, timeout => 60);
}
