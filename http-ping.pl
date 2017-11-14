#!/usr/bin/perl  -w
#
# Program: HTTP Ping <http-ping.pl>
#
# Author: Matty < matty91 at gmail dot com >
#
# Current Version: 1.1
#
# Revision History:
#
# Version 1.1
#     Added checks for arguments
#
# Version 1.0
#     Original release
#
# Last Updated: 09-13-2005
#
# Purpose:
#  Reports latency between a web server and a given host
#
# License:
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the
#   Free Software Foundation; either version 2, or (at your option) any
#   later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# Installation:
#   Install Net::HTTP, and copy the shell script to a suitable location
#
# Usage
#  Usage: http-ping.pl [ -s server ] [ -p port ] [ -d delay ] [ -u uri ] [ -h ]
#
# Example:
#  ./http-ping.pl -s www.prefetch.net -p 80 -d 5 -u /index.html
#   Querying HTTP server www.prefetch.net:80 every 5 seconds (Ctrl-C to stop):
#      Mon Nov 29 18:09:59 2004: TCP Connection Time=0.052s HTTP GET Time=0.051s [Normal Delay]
#      Mon Nov 29 18:10:04 2004: TCP Connection Time=0.036s HTTP GET Time=0.052s [Normal Delay]
#      Mon Nov 29 18:10:09 2004: TCP Connection Time=0.034s HTTP GET Time=0.052s [Normal Delay]

use Net::HTTP;
use Time::HiRes qw (time);
use Getopt::Std;

############################
# Globals                  #
############################
my $httpConnection = 0;
my $content = 0;
my $buffer = 0;
my $buffer_size = 8192;
my $excessive_delay = 1;

####################################
# Get the parameters from the user #
####################################
%options=();
getopts("d:hp:s:u:",\%options);

my $delay = defined($options{d}) ? $options{d} : 10;
my $port = defined($options{p}) ? $options{p} : 80;
my $server = defined($options{s}) ? $options{s} : "localhost";
my $uri = defined($options{u}) ? $options{u} : "/";

if (defined $options{h} ) {
        printf("Usage: http-ping.pl [ -s server ] [ -p port ] [ -d delay ] [ -u uri ] [ -h ]\n");
        exit(1);
}

#######################################
# Let the user know what we are doing #
#######################################

printf("Issuing GET request for $uri on HTTP server $server:$port every $delay seconds (Ctrl-C to stop):\n");

#############################
# Connect to server         #
#############################
while (1) {
	# Calculate the time it takes to establish a TCP connection ( SYN, SYN/ACK, ACK )
	my $start = time();
	my $httpConnection = Net::HTTP->new( Host => $server ) 
		|| die $@;
	my $tcpConnectionTime = time() - $start;

	# Calculate the time it takes to GET / and process it
	$start = time();

	$httpConnection->write_request(GET => "$uri", "User-Agent" => "MTY/1.0.5f");

	while (  $content =  $httpConnection->read_entity_body($buffer, $buffer_size) ) {
	}
	my $httpConnectionTime = time() - $start;

	if ( ($tcpConnectionTime > $excessive_delay) || ( $httpConnectionTime > $excessive_delay))  {
             my $dt = scalar localtime time;
	     printf("  %s: TCP Connection Time=%.3fs HTTP GET Time=%.3fs [Excessive Delay]\n",$dt, $tcpConnectionTime, $httpConnectionTime);
	} else {
             my $dt = scalar localtime time;
             printf("  %s: TCP Connection Time=%.3fs HTTP GET Time=%.3fs [Normal Delay]\n",$dt, $tcpConnectionTime, $httpConnectionTime);
	}

	sleep($delay);
}
