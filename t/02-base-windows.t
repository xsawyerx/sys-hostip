#!perl

use strict;
use warnings;
use lib '.';
use t::lib::Utils qw/base_tests mock_win32_hostip/;
use Test::More;

my @ipconfigs = qw(
  ipconfig-2k.txt
  ipconfig-win10.txt
  ipconfig-win2008-sv_SE.txt
  ipconfig-win7-de_DE.txt
  ipconfig-win7-empty-name.txt
  ipconfig-win7-fi_FI.txt
  ipconfig-win7-fr_FR.txt
  ipconfig-win7-it_IT.txt
  ipconfig-win7.txt
  ipconfig-xp.txt
);

# The "2" here is the checks that the Windows mocking was run
plan tests => ( 6 + 2 )* scalar @ipconfigs;

# run mocked windows base tests
for my $ipconfig ( @ipconfigs ) {
    note $ipconfig;

    # Mock Windows
    local $Sys::HostIP::IS_WIN = 1;

    my $hostip = mock_win32_hostip($ipconfig);
    base_tests($hostip);
}
