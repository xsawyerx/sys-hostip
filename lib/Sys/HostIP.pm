use strict;
use warnings;
package Sys::HostIP;

use Carp;
use Exporter;
use vars qw($VERSION @ISA @EXPORT_OK);

$VERSION   = '1.4';
@ISA       = qw(Exporter);
@EXPORT_OK = qw( ip ips interfaces ifconfig );

{
  #cache value, except when a new value is specified
  my $ifconfig;
  
  sub ifconfig {
    my ($class, $new_ifconfig) = @_;
    if (defined $new_ifconfig) {
      $ifconfig = $new_ifconfig;
    } elsif (defined $ifconfig) {
      # do nothing, since we're keeping the cached value
    } elsif ($^O =~ /(linux|openbsd|freebsd|netbsd|solaris|darwin)/) {
      $ifconfig =  '/sbin/ifconfig -a';
    } elsif ($^O eq 'aix') {
      $ifconfig = '/usr/sbin/ifconfig -a';
    } elsif  ($^O eq 'irix') {
      $ifconfig = '/usr/etc/ifconfig';
    } else {
      carp "Unknown system ($^O), guessing ifconfig lives in /sbin/ifconfig (email bluelines\@divisionbyzero.com with your system info)\n";
      $ifconfig = '/sbin/ifconfig -a';
    }
    return $ifconfig;
  }
}

sub ip {
  my ($class) = @_;
  $class = "Sys::HostIP" unless defined $class;
  return $class->_get_interface_info(mode => 'ip');
}

sub ips {
  my ($class) = @_;
  $class = "Sys::HostIP" unless defined $class;
  return $class->_get_interface_info(mode => 'ips');
}

sub interfaces {
  my ($class) = @_;
  $class = "Sys::HostIP" unless defined $class;
  return $class->_get_interface_info(mode => 'interfaces');
}

sub _get_interface_info {
  my ($class, %params) = @_;
  my $if_info = {};
  if ($^O =~/(MSWin32|cygwin)/) {
    $if_info = $class->_get_win32_interface_info();
  } else {
    $if_info = $class->_get_unix_interface_info();
  }
  if ($params{mode} eq 'interfaces') {
    return $if_info;
  } elsif ( $params{mode} eq 'ips') {
    return [values %$if_info];
  } elsif ( $params{mode} eq 'ip') {
    if ($^O =~/(MSWin32|cygwin)/) {
      foreach my $key (sort keys %$if_info) {
    #should this be the default?
    if ($key=~/Local Area Connection/) {
      return ($if_info->{$key});
    }
      }
    } else {
      foreach my $key (sort keys %$if_info) {
    #we don't want the loopback
    next if ($if_info->{$key} eq '127.0.0.1');
    #now we return the first one that comes up
    return ($if_info->{$key});
      }
      #we get here if loopback is the only active device
      return "127.0.0.1";
    }
  }
}

sub _get_unix_interface_info {
  my ($class) = @_;
  my %if_info;
  my ($ip, $interface) = undef;
  #this is an attempt to fix tainting problems
  local %ENV;
  # $BASH_ENV must be unset to pass tainting problems if your system uses
  # bash as /bin/sh
  if (exists $ENV{'BASH_ENV'} and defined $ENV{'BASH_ENV'}) {
    $ENV{'BASH_ENV'} = undef;
  }
  #now we set the local $ENV{'PATH'} to be only the path to ifconfig
  my ($newpath)  = ( $class->ifconfig =~/(\/\w+)(?:\s\S+)$/) ;
  $ENV{'PATH'} = $newpath;
  my $ifconfig = $class->ifconfig;
  # make sure nothing else has touched $/
  local $/ = "\n";
  my @ifconfig = `$ifconfig`;
  foreach my $line (@ifconfig) {
    #output from 'ifconfig -a' looks something like this on every *nix i
    #could get my hand on except linux (this one's actually from OpenBSD):
    #
    #gershiwin:~# /sbin/ifconfig -a
    #lo0: flags=8009<UP,LOOPBACK,MULTICAST>
    #        inet 127.0.0.1 netmask 0xff000000 
    #lo1: flags=8008<LOOPBACK,MULTICAST>
    #xl0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST>
    #        media: Ethernet autoselect (100baseTX full-duplex)
    #        status: active
    #        inet 10.0.0.2 netmask 0xfffffff0 broadcast 10.0.0.255
    #sl0: flags=c010<POINTOPOINT,LINK2,MULTICAST>
    #sl1: flags=c010<POINTOPOINT,LINK2,MULTICAST>
    #
    #in linux it's a little bit different:
    #
    #[jschatz@nooky Sys-IP]$ /sbin/ifconfig 
    # eth0      Link encap:Ethernet  HWaddr 00:C0:4F:60:6F:C2  
    #          inet addr:10.0.3.82  Bcast:10.0.255.255  Mask:255.255.0.0
    #          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
    #          Interrupt:19 Base address:0xec00 
    # lo        Link encap:Local Loopback  
    #          inet addr:127.0.0.1  Mask:255.0.0.0
    #          UP LOOPBACK RUNNING  MTU:3924  Metric:1
    #
    # so the regexen involved here have to deal with the following: 1)
    # there's no ':' after an interface's name in linux 2) in linux, it's
    # "inet addr:127.0.0.1" instead of "inet 127.0.0.1" hence the somewhat
    # hairy regexen /(^\w+(?:\d)?(?:\:\d)?)/ (which also handles aliased ip
    # addresses , ie eth0:1) and /inet(?:addr\:)?(\d+\.\d+\.\d+\.\d+)/
    #
    #so we parse through the list returned. if the line starts with some
    #letters followed (possibly) by an number and a colon, then we've got an
    #interface. if the line starts with a space, then it's the info from the
    #interface that we just found, and we stick the contents into %if_info
    if ( ($line =~/^\s+/) && ($interface) ) {
      $if_info{$interface} .= $line;
    }
    elsif (($interface) = ($line =~/(^\w+(?:\d)?(?:\:\d+)?)/)) {
      $line =~s/\w+\d(\:)?\s+//;
      $if_info{$interface} = $line;
    }
  }
    foreach my $key (keys %if_info) {
      #now we want to get rid of all the other crap in the ifconfig
      #output. we just want the ip address. perhaps a future version can
      #return even more useful results (netmask, etc).....
      if (my ($ip) = ($if_info{$key} =~/inet (?:addr\:)?(\d+(?:\.\d+){3})/)) {
    $if_info{$key} = $ip;
      }
      else {
    #ok, no ip address here, which means this interface isn't
    #active. some os's (openbsd for instance) spit out ifconfig info for
    #inactive devices. this is pretty much worthless for us, so we
    #delete it from the hash
    delete $if_info{$key};
      }
    }
  #now we do some cleanup by deleting keys that have no associated info
  #(some os's like openbsd list inactive interfaces when 'ifconfig -a' is
  #used, and we don't care about those
  return \%if_info;
} 

sub _get_win32_interface_info {
  my ($class) = @_;
  my %if_info;
  my ($line, $interface)= undef;
  local $/ = "\r\n";
  my @ipconfig = `ipconfig`;
  foreach my $line (@ipconfig) {
    chomp($line);
    if ($line =~/^Windows IP Configuration/) {
      #ignore the header
      next;
    } elsif ($line =~/^\s$/) {
      next;
    } elsif ( 
         ($line =~/\s+IP Address.*:\s+(\d+(?:\.\d+){3})/) and $interface) {
      $if_info{$interface} = $1;
      $interface = undef;
    } elsif ($line =~/^Ethernet adapter\s+(.*):/) {
      $interface = $1;
      chomp($interface);
    }
  }
  return \%if_info;
}

1;

__END__

=head1 NAME

Sys::HostIP - Try extra hard to get ip address related info

=head1 SYNOPSIS

  use Sys::HostIP; 
  
  #class methods 
  my $ip_address = Sys::HostIP->ip; 

  # $ip_address is a scalar containing a best guess of your host machines 
  # ip address. On unix systems, it will return loopback (127.0.0.1) if it 
  # can't find anything else. This is also exported as a sub (to keep 
  # compatability with older versions).

  my $ip_addresses = Sys::HostIP->ips; 

  # $ip_addresses is an array ref containing all the ip addresses of your
  # machine 

  my $interfaces = Sys::HostIP->interfaces;

  # $interfaces is a hash ref containg all pairs of interfaces/ip addresses
  # Sys::HostIP could find on your machine.

  Sys::HostIP->ifconfig("/somewhere/that/ifconfig/lives");
  # you can set the location of ifconfig with this class method if the code
  # doesn't seem to know where your ifconfig lives

=head1 DESCRIPTION

Sys::HostIP does what it can to determine the ip address of your
machine. All 3 methods work fine on every system that I've been able to test
on. (Irix, OpenBSD, FreeBSD, NetBSD, Solaris, Linux, OSX, Win32, Cygwin). It 
does this by parsing ifconfig(8) (ipconfig on Win32/Cygwin) output. 

=head2 EXPORT

Nothing by default!

But, if you ask for it nicely, you'll get:

ip(), ips(), interfaces(), and ifconfig(). 

To export something explicitly, use the syntax:

    use HostIP qw/ip ips interfaces/;
    # that will get you those three subroutines, for example

=head1 AUTHOR

Originally written by Jonathan Schatz <bluelines@divisionbyzero.com>.

Currently maintained by Sawyer X <xsawyerx@cpan.org>.

=head1 TODO

I haven't tested the win32 code with dialup or wireless connections.

=head1 SEE ALSO

=over 4

=item * ifconfig(8)

=item * ipconfig

=back

