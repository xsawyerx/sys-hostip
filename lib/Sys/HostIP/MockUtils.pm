package Sys::HostIP::MockUtils;
# ABSTRACT: Mocking utilities to help testing multiple systems

use strict;
use warnings;

use Carp;
use Exporter;
use vars qw( @ISA @EXPORT_OK );

@ISA       = qw(Exporter);
@EXPORT_OK = qw( mock_run_ipconfig );

sub mock_run_ipconfig {
    my $filename = shift;
    my $file     = File::Spec->catfile( 't', 'data', $filename );

    open my $fh, '<', $file or die "Error opening $file: $!\n";
    my @output = <$fh>;
    close $fh or die "Error closing $file: $!\n";

    return @output;
}
