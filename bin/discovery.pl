#!/usr/bin/env perl
###
# This script will discover streams in the configured Graylog servers.
# The discovered streams will be posted to a discovery item of the
# host in Zabbix.
###

use 5.24.0;
use strict;
use warnings;

use YAML::Tiny;
use IPC::Cmd 'run';
use File::Temp 'tempfile';

my $verbose            = $ENV{'MOJO_VERBOSE'}    || 0;
my $configfile         = $ENV{'MOJO_CONFIGFILE'} || './config.yml';
my $config             = YAML::Tiny->read($configfile)->[0] || die "Can't read '$configfile': $!";
my $zbx_server         = $config->{'zabbix'}{'server'};

my $zbx_discovery_item = 'gzalertmon.discovery';

my $jq                 = '/usr/bin/jq';
my $curl               = '/usr/bin/curl';
my $zbx_sender         = '/usr/bin/zabbix_sender';

my ($fh, $filename)    = tempfile();

foreach my $graylog (@{$config->{'graylog'}}) {
  my $zbx_host = $graylog->{'hostname'};

  my $url      = $graylog->{'rest'}{'url'};
  my $username = $graylog->{'rest'}{'username'};
  my $password = $graylog->{'rest'}{'password'};

  my $command  = [
    $curl,
      '-sXGET',
      "$url/streams/enabled",
      '--user',
      "$username:$password",
    '|',
    $jq,
      '-M',
      '-c',
      "[[.streams[].title][] | {\"{#STREAMNAME}\": .}] | {data:.}"
  ];

  my $output = (run(
      command => $command,
      verbose => $verbose,
      timeout => 60)
  )[3][0];

  die "Discovery failure" unless $output;

  print $fh "\"$zbx_host\" $zbx_discovery_item $output";
}

close $fh;

my $command = [
  $zbx_sender,
  '-z', $zbx_server,
  '-i', $filename
];

run(
  command => $command,
  verbose => $verbose,
  timeout => 60
) and unlink($filename);
