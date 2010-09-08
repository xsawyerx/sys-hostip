#!perl

use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;
use Sys::HostIP qw/ip ips ifconfig interfaces/;

lives_ok { ip()         } 'ip()         imported explicitly';
lives_ok { ips()        } 'ips()        imported explicitly';
lives_ok { ifconfig()   } 'ifconfig()   imported explicitly';
lives_ok { interfaces() } 'interfaces() imported explicitly';

