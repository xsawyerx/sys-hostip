#!perl

use strict;
use warnings;

use Test::More;
use Sys::HostIP qw/ip ips ifconfig interfaces/;
use File::Spec;

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

plan tests => 6 * (@ipconfigs + 1);

main() unless caller;

sub main {
    # run base tests on actual system
    my $hostip = Sys::HostIP->new;
    base_tests($hostip);

    # run mocked windows base tests
    for my $ipconfig ( @ipconfigs ) {
        my $hostip = mock_win32_hostip($ipconfig);
        base_tests($hostip);
    }
}

sub base_tests {
    my $hostip = shift;

    # -- ip() --
    my $sub_ip   = ip();
    my $class_ip = $hostip->ip;

    diag("Class IP: $class_ip");
    like( $class_ip, qr/^ \d+ (?: \. \d+ ){3} $/x, 'IP by class looks ok' );
    is( $class_ip, $sub_ip, 'IP by class matches IP by sub' );

    # -- ips() --
    my $class_ips = $hostip->ips;
    isa_ok( $class_ips, 'ARRAY', 'scalar context ips() gets arrayref' );
    ok( 1 == grep( /^$class_ip$/, @{$class_ips} ), 'Found IP in IPs by class' );

    # -- interfaces() --
    my $interfaces = $hostip->interfaces;
    isa_ok( $interfaces, 'HASH', 'scalar context interfaces gets hashref' );
    cmp_ok(
        scalar keys ( %{$interfaces} ),
        '==',
        scalar @{$class_ips},
        'Matching number of interfaces and ips',
    );
}

sub mock_win32_hostip {
    my $file = shift;

    no warnings qw/redefine once/;

    my $hostip = Sys::HostIP->new;
    *Sys::HostIP::_is_win = sub { return 1 };
    *Sys::HostIP::_run_ipconfig = sub { return mock_run_ipconfig($file) };

    $hostip->{'if_info'} = $hostip->_get_interface_info;

    return $hostip;
}

sub mock_run_ipconfig {
    my $filename = shift;
    my $file     = File::Spec->catfile( 't', 'data', $filename );

    open my $fh, '<', $file or die "Error opening $file: $!\n";
    my @output = <$fh>;
    close $fh or die "Error closing $file: $!\n";

    return @output;
}
