use strict;
use warnings;

use Test::More tests => 4;
use Test::TinyMocker;

use File::Spec;
use Sys::HostIP;

sub mock_run_ipconfig {
    my $filename = shift;
    my $file     = File::Spec->catfile( 't', 'data', $filename ); 

    open my $fh, '<', $file or die "Error opening $file: $!\n";
    my @output = <$fh>;
    close $fh or die "Error closing $file: $!\n";

    return @output;
}

my $hostip = Sys::HostIP->new;

mock 'Sys::HostIP'
    => method '_run_ipconfig'
    => should {
        my $self = shift;
        isa_ok( $self, 'Sys::HostIP' );

        return mock_run_ipconfig('ipconfig-2k.txt');
    };

is_deeply(
    { 'Local Area Connection' => '169.254.109.232' },
    $hostip->_get_win32_interface_info,
    'Correct Win2K interface',
);

mock 'Sys::HostIP'
    => method '_run_ipconfig'
    => should {
        my $self = shift;
        isa_ok( $self, 'Sys::HostIP' );

        return mock_run_ipconfig('ipconfig-xp.txt');
    };

is_deeply(
    { 'Local Area Connection' => '0.0.0.0' },
    $hostip->_get_win32_interface_info,
    'Correct WinXP interface',
);

