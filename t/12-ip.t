#!perl

use strict;
use warnings;
use t::lib::Utils qw/mock_linux_hostip base_tests/;

use Test::More;
use Sys::HostIP;

if ($^O =~ qr/(MSWin32|cygwin)/x) {
    plan tests =>  0;
}
else {
    plan tests =>  11;
    my $hostip = mock_linux_hostip('ip-linux.txt');
    base_tests($hostip);
}
