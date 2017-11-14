#!/usr/bin/perl -w
#
# Program: LDAP Ping <ldap-ping.pl>
#
# Author: Matty < matty91 at gmail dot com >
#
# Current Version: 1.3
# 
# Revision History:
#
# Version 1.3
#  - Fixed a typo in getopts -- Glynn Kennedy
#
# Version 1.2
#  - Added SSL support
#  - Added support for binddns and passwords
#  - Added support for search bases
#  - Created usage sub routine 
#  - Use Socket module, which removes the pfiles dependency -- code 
#    contributed by Jay Soffian
#  - Use localtime instead of existing date routines -- code 
#    contributed by Jay Soffian
#
# Version 1.1
#     Added checks for arguments
#
# Version 1.0
#     Original release
#
# Last Updated: 01-07-2007
#
# Purpose:
#  Reports latency between a directory server and a given host
#
# Installation:
#   Copy the shell script to a suitable location
#
# Usage:
#   Usage: ldap-ping.pl -s server [ -p port ] [ -d delay ] [ -h ] \
#                       [ -b base ] [ -u binddn ] [ -e ] [ -w passwd ]
#
# Example:
#   $ ldap-ping.pl -s ldap.prefetch.net -p 636 -d 10 -e -b "ou=contacts,dc=prefetch,dc=net" -u "cn=ping"
#
#   Querying LDAP server ldap.prefetch.net:636 every 10 seconds (Ctrl-C to stop):
#   Tue May 24 14:11:05 2005: new=0.253s, = bind=0.022s, search=0.066s, unbind=0.005s [local port=34039] [Normal Delay]
#   Tue May 24 14:11:15 2005: new=0.069s, = bind=0.009s, search=0.009s, unbind=0.002s [local port=34041] [Normal Delay]
#   Tue May 24 14:11:25 2005: new=0.067s, = bind=0.009s, search=0.009s, unbind=0.002s [local port=34042] [Normal Delay]
#

use Time::HiRes qw (time);
use Getopt::Std;
use Net::LDAP;
use Net::LDAPS;
use Socket;

# Define the excessive_delay to use
my $excessive_delay = 1;

# Define the remaining variables
my $start = 0, $localport = 0;
my $new = 0, $bind = 0, $search = 0, $unbind = 0, $ldap = 0;

sub usage () {
        printf("\nUsage: ldap-ping.pl -s server [ -p port ] [ -d delay ] [ -h ]\n");
	printf("       [ -b base ] [ -u binddn ] [ -e ] [ -w passwd ]\n\n");
	printf("   -b BASE   : Base to start searching\n");
        printf("   -d NUMBER : Specifies the delay to use between invocations\n");
        printf("   -e        : Use SSL\n");
	printf("   -h        : Print this menu\n");
        printf("   -p NUMBER : Port number to connect to\n");
        printf("   -s HOST   : Hostname to connect to\n");
        printf("   -u STRING : Bind DN to use\n");
	printf("   -w PASSWD : Password to use with Bind DN\n\n");
	exit(1);
}


### See what was passed on the command line
%options=();
getopts("b:d:hep:s:u:w:",\%options);

my $base = $options{b} || "";
my $delay = $options{d} || 60;
my $dn = $options{u} || "";
my $ssl = $options{e} || 0;
my $port = $options{p} || 389;
my $server = $options{s} || usage;
my $password = $options{w} || 0;

if (defined $options{h} ) {
        usage;
}

printf("Querying LDAP server $server:$port every $delay seconds (Ctrl-C to stop):\n");

while (1) { 

	###
	### Calculate the time it takes to create a TCP connection and
	### perform the SSL handshake ( if "-e" was passed on the command line )
	###
        $start = time();

	if ( $ssl == 1 ) {
                $ldap =  new Net::LDAPS($server, port => $port) or die("Cannot create SSL connection to $server:$port");
        } else {
		$ldap = new Net::LDAP($server, port=> $port) or die("Cannot create TCP connection to $server:$port");
	}

        $new = time() - $start;


	###
	### Calculate the time it takes to bind
	###
	$start = time();
	if ( defined($dn) ) {
        	$ldap->bind( $dn,
                  "password" => $password,
                  "base"     => $base,
                  "version"  => 3) or die("Cannot bind as $dn:$password with base $base");
        } else {
        	$ldap->bind( "base"     => $base,
                  version  => 3) or die("Cannot perform anonymous bind with base $base");
        }
        $bind = time() - $start;

	###
	### Grab the local port number
	###
	($localport) = sockaddr_in($ldap->socket()->sockname());

	###
	### Calculate the time it takes to search
	###
        $start = time();
	$ldap->search(
                "base"   => $base,
                "filter" => "(objectclass=*)",
                "attrs"  => "cn",
                "scope"  => "base"
        ) or die("Unable to search base $base");
        $search = time() - $start;

	###
	### Calculate the time it takes to unbind
	###
        $start = time();
        $ldap->unbind() or die("Unable to unbind from $server:$port");
        $unbind = time() - $start;

	###
	### Check to see if the delay is greater than $excessive_delay
	###
        if (($new > $excessive_delay) || ($bind > $excessive_delay) || 
            ($search > $excessive_delay) || ($unbind > $excessive_delay)) {
		my $dt = scalar localtime time;
        	my $ds = $is_excessive ? "Excessive" : "Normal";
		printf("%s: new=%.3fs, = bind=%.3fs, search=%.3fs, unbind=%.3fs [local port=%d] [Excessive Delay]\n", $dt, $new, $bind, $search, $unbind, $localport);
        } else {
               my $dt = scalar localtime time;
               my $ds = $is_excessive ? "Excessive" : "Normal";
               printf "%s: new=%.3fs, = bind=%.3fs, search=%.3fs, unbind=%.3fs [local port=%d] [Normal Delay]\n", $dt, $new, $bind, $search, $unbind, $localport;
        }

        sleep($delay);
}
