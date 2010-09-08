#!perl

use strict;
use warnings;
use Test::More tests => 16;
use Test::Exception;

my @all_subs = qw/ip ips ifconfig interfaces/;

{
    use Sys::HostIP;

    TODO: {
        local $TODO = 'Pending feature - no unwarranted pollution';

        throws_ok { ip() } qr/^Undefined subroutine/,
            'ip() was not imported';

        throws_ok { ips() } qr/^Undefined subroutine/,
            'ips() was not imported';

        throws_ok { ifconfig() } qr/^Undefined subroutine/,
            'ifconfig() was not imported';

        throws_ok { interfaces() } qr/^Undefined subroutine/,
            'interfaces() was not imported';
    };
}

{
    use Sys::HostIP @all_subs;
    lives_ok { ip()         } 'ip()         imported explicitly';
    lives_ok { ips()        } 'ips()        imported explicitly';
    lives_ok { ifconfig()   } 'ifconfig()   imported explicitly';
    lives_ok { interfaces() } 'interfaces() imported explicitly';
}

{
    use Sys::HostIP @all_subs;

    my $class = 'Sys::HostIP';

    # -- ip() --
    my $sub_ip   = ip();
    my $class_ip = $class->ip;

    ok( $class_ip =~ /^ \d+ (?: \. \d+ ){3} $/x, 'IP by class looks ok' );
    is( $class_ip, $sub_ip, 'IP by class matches IP by sub' );

    # -- ips() --
    my $class_ips = $class->ips;
    isa_ok( $class_ips, 'ARRAY', 'scalar context ips() gets arrayref' );
    ok( 1 == grep( /^$class_ip$/, @{$class_ips} ), 'Found IP in IPs by class' );

    # skipping in case it's MSWin32 or cygwin?
    SKIP: {
        skip 'Issues on Windows' => 1 if $^O =~ /(MSWin32|cygwin)/;
        ok(
            1 == grep( /^127\.0\.0\.1$/, @{$class_ips} ),
            'Found 127.0.0.1 once in IPs by class',
        );
    };

    # -- interfaces() --
    my $interfaces = $class->interfaces;
    isa_ok( $interfaces, 'HASH', 'scalar context interfaces gets hashref' );
    cmp_ok(
        scalar keys ( %{$interfaces} ),
        '==',
        scalar @{$class_ips},
        'Matching number of interfaces and ips',
    );

    # skipping in case it's MSWin32 or cygwin?
    SKIP: {
        skip 'Issues on Windows' => 1 if $^O =~ /(MSWin32|cygwin)/;
        ok(
            grep( /^127\.0\.0\.1$/, values %{$interfaces} ),
            'Found 127.0.0.1 in interfaces',
        );
    };
}

