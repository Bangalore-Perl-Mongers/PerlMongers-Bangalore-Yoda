#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use PerlMongers::Bangalore::Yoda;
use Log::Log4perl qw(get_logger);

my $log_cfg = '/etc/shantanubhadoria/Log4perl.conf';
Log::Log4perl::init_and_watch( $log_cfg, 10 );

PerlMongers::Bangalore::Yoda->run();
