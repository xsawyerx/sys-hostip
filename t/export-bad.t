#!perl

use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;
use Sys::HostIP;

throws_ok { ip() } qr/^Undefined subroutine/,
    'ip() was not imported';

throws_ok { ips() } qr/^Undefined subroutine/,
    'ips() was not imported';

throws_ok { ifconfig() } qr/^Undefined subroutine/,
    'ifconfig() was not imported';

throws_ok { interfaces() } qr/^Undefined subroutine/,
    'interfaces() was not imported';
