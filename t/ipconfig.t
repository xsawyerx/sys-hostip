use strict;
use warnings;

use Test::More tests => 2 * 3;
use Test::TinyMocker;

use File::Spec;
use Sys::HostIP;

my $hostip = Sys::HostIP->new;

sub mock_run_ipconfig {
    my $filename = shift;
    my $file     = File::Spec->catfile( 't', 'data', $filename ); 

    open my $fh, '<', $file or die "Error opening $file: $!\n";
    my @output = <$fh>;
    close $fh or die "Error closing $file: $!\n";

    return @output;
}

sub mock_and_test {
    my ( $file, $expected_results, $test_name ) = @_;

    mock 'Sys::HostIP'
        => method '_run_ipconfig'
        => should {
            my $self = shift;
            isa_ok( $self, 'Sys::HostIP' );

            return mock_run_ipconfig($file);
        };

    is_deeply(
        $expected_results,
        $hostip->_get_win32_interface_info,
        $test_name,
    );

}

mock_and_test(
    'ipconfig-2k.txt',
    { 'Local Area Connection' => '169.254.109.232' },
    'Correct Win2K interface',
);

mock_and_test(
    'ipconfig-xp.txt',
    { 'Local Area Connection' => '0.0.0.0' },
    'Correct WinXP interface',
);

mock_and_test(
    'ipconfig-win7.txt',
    {
        'Local Area Connection'   => '192.168.0.10',
        'Local Area Connection 2' => '192.168.1.20',
    },
    'Correct Win7 interface',
);

