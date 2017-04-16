package t::lib::MockUtils;
# ABSTRACT: Mocking utilities to help testing multiple systems

use strict;
use warnings;

use Carp;
use Exporter;
use vars qw( @ISA @EXPORT_OK );

use File::Spec;

@ISA       = qw(Exporter);
@EXPORT_OK = qw( mock_run_ipconfig mock_win32_hostip );

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

1;
