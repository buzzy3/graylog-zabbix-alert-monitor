#!/usr/bin/env perl
###
# This script translates callbacks from graylog alerts to values in zabbix
###

use Mojo::Log;
use Mojolicious::Lite;

use YAML::Tiny;
use Data::Dumper;
use IPC::Cmd 'run';

my $verbose    = $ENV{'MOJO_VERBOSE'}    || 0;
my $configfile = $ENV{'MOJO_CONFIGFILE'} || './config.yml';
my $config     = YAML::Tiny->read($configfile)->[0] || die "Can't read '$configfile': $!";
my $zbx_sender = '/usr/bin/zabbix_sender';

my $logger  = Mojo::Log->new;

helper zabbix_sender => sub {
  my $c          = shift;
  my $zbx_host   = shift;
  my $stream     = shift;
  my $grace      = shift;
  my $severity   = shift;
  my $zbx_server = $config->{'zabbix'}{'server'};
  
  my $timestamp  = time() + (($grace+1) * 60);
  my $command    = [
    $zbx_sender,
    '-z', $zbx_server,
    '-s', $zbx_host,
    '-k', "gzalertmon.grace[$severity,$stream]",
    '-o', $timestamp
  ];

  return (run(
    command => $command,
    verbose => $verbose,
    timeout => 5,
  ))[0];
};

under '/' => sub {
  my $c = shift;
  $c->res->headers->remove('Server');
};

post '/alert/:severity' => sub {
  my $c = shift;

  my $zbx_host;
  foreach my $graylog (@{$config->{'graylog'}}) {
    foreach my $ip (@{$graylog->{'ipaddress'}}) {
      $zbx_host = $graylog->{'hostname'} if $ip eq $c->tx->remote_address;
      last if $zbx_host;
    }
  }

  # Check whether host is configured
  unless ($zbx_host) {
    $logger->warn("Unknown zabbix-host: " . $c->tx->remote_address);
    $c->render(status => 403, json => {});
    return undef;
  }
  $logger->info("Alert for zabbix-host: $zbx_host [" . $c->tx->remote_address . "]");

  # Check for valid severity
  my $severity = $c->stash('severity');
  if ((! $severity) || ($severity !~ /^warning|critical$/)) {
    $logger->warn("Invalid severity: $severity");
    $c->render(status => 400, json => {});
    return undef;
  }

  # Check empty body
  my $body = $c->req->json;
  if ((! $body) || (! keys %$body)) {
    $logger->warn("Empty POST body");
    $c->render(status => 400, json => {});
    return undef;
  }

  # Define stream
  my $stream_title = $body->{'stream'}{'title'};
  my $alert_grace  = $body->{'check_result'}{'triggered_condition'}{'grace'};

  # Check for valid json
  unless ($stream_title && defined $alert_grace) {
    $logger->warn("Malformed POST body");
    $logger->warn(Dumper $body);
    $c->render(status => 400, json => {});
    return undef;
  }

  $logger->info("Alert for stream: '$stream_title', with grace: $alert_grace");

  if ($c->zabbix_sender($zbx_host, $stream_title, $alert_grace, $severity)) {
    $logger->info("Sent item value using zabbix_sender");
    $c->render(status => 201, json => {});
  } else {
    $logger->error("Problem executing zabbix_sender");
    $c->render(status => 503, json => {});
  }
};

app->start;
