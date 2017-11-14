#!/usr/bin/perl -w
#
# Program: LDAP Statistics Collector <ldap-gather.pl>
#
# Author: Matty < matty91 @ gmail dot com >
#
# Current Version: 2.0
#
# Last Updated: 09-18-2005
#
# Purpose: 
#   ldap-gather is a Perl script designed to extract various performance
#   metrics from an OpenLDAP server
#
# Usage:
#   Please see the usage() sub-routine.
#
# Installation: 
#   Install Net::LDAP and copy the Perl script to a suitable location
# 
# Examples:
#  The following example will grab the latest set of LDAP statistics
#  from ldap.prefetch.net:
#     $ ldap-gather.pl -s ldap.prefetch.net -p 389 -d /var/ldap/ldap.stats

use Net::LDAP;
use Getopt::Std;

#######################################
# Functions
#######################################

# Create a universal usage routine to call if problems are detected
sub usage () {
        printf("Usage: ldap-gather.pl [ -s server ] [ -p port ] [ -h ] [ -d Absolute path to statistics file ]\n");
        printf("  -s server : Hostname to connect to\n");
        printf("  -p port   : TCP port to connect to\n");
        printf("  -d file   : Statistics file to store headers and monitor DN statistics (e.g., /tmp/ldap.stats.txt )\n");
	exit(1);
}

# Borrowed from code written by Quanah Gibson-Mount
sub getMonitorDesc {
        my $dn = $_[0];
        my $attr = $_[1];
	my $ldapstruct = $_[2];

        if (!$attr) { 
                 $attr="description";
        }

        my $searchResults = $ldapstruct->search(base => "$dn",
                            scope => 'base',
                            filter => 'objectClass=*',
                            attrs => ["$attr"],);
        my $entry = $searchResults->pop_entry() if $searchResults->count() == 1;
        $entry->get_value("$attr");
}

#######################################
#  Global variables get set to 0 here #
#######################################
my $timestamp = time();

###################################
# Get the arguments from the user #
###################################
%options=();
getopts("hp:s:d:",\%options);

my $statsfile = $options{d} ||  usage();
my $port = $options{p} || 389;
my $server = $options{s} || "localhost";

if (defined $options{h} ) {
	usage();
}

if ( ! defined($statsfile)) {
	usage();
}

######################################
# Open the file if it doesn't exist  #
######################################
if ( -e $statsfile ) {
        # The file exists, so there is no reason to add a heading
        open (LDAPFILE, ">>$statsfile") || die "ERROR: Couldn't open $statsfile in append mode Perl error: $@";

} else {
        # The file doesn't exist, so let's add a heading
        open(LDAPFILE, ">$statsfile") || die "ERROR: Couldn't open $statsfile in write mode: Perl error: $@";
        print LDAPFILE "TIMESTAMP TOTAL_CONNECTIONS BYTES_SENT INITIATED_OPERATIONS COMPLETED_OPERATIONS ";
        print LDAPFILE "REFERRALS_SENT ENTRIES_SENT BIND_OPERATIONS UNBIND_OPERATIONS ADD_OPERATIONS ";
        print LDAPFILE "DELETE_OPERATIONS MODIFY_OPERATIONS COMPARE_OPERATIONS SEARCH_OPERATIONS WRITE_WAITERS READ_WAITERS\n";
}


###################################################
# Create new connection and bind to the server    #
###################################################
my $ldap = new Net::LDAP($server, port=> $port) or die "Failed to create socket to $server:$port: Perl error:  $@";

$ldap->bind(
           "base"     => "",
           "version"  => 3
) or die "Failed to bind to LDAP server: Perl error: $@";

###############################################
# Collect the statistics from the server      #
###############################################
my $total_connections = getMonitorDesc("cn=Total,cn=Connections,cn=Monitor","monitorCounter",$ldap);
my $bytes_sent = getMonitorDesc("cn=Bytes,cn=Statistics,cn=Monitor","monitorCounter",$ldap);
my $completed_operations = getMonitorDesc("cn=Operations,cn=Monitor","monitorOpCompleted",$ldap);
my $initiated_operations = getMonitorDesc("cn=Operations,cn=Monitor","monitorOpInitiated",$ldap);
my $referrals_sent = getMonitorDesc("cn=Referrals,cn=Statistics,cn=Monitor","monitorCounter",$ldap);
my $entries_sent = getMonitorDesc("cn=Entries,cn=Statistics,cn=Monitor","monitorCounter",$ldap);
my $bind_operations = getMonitorDesc("cn=Bind,cn=Operations,cn=Monitor","monitorOpCompleted",$ldap);
my $unbind_operations = getMonitorDesc("cn=Unbind,cn=Operations,cn=Monitor","monitorOpCompleted",$ldap);
my $add_operations = getMonitorDesc("cn=Add,cn=Operations,cn=Monitor","monitorOpInitiated",$ldap);
my $delete_operations =  getMonitorDesc("cn=Delete,cn=Operations,cn=Monitor","monitorOpCompleted",$ldap);
my $modify_operations = getMonitorDesc("cn=Modify,cn=Operations,cn=Monitor","monitorOpCompleted",$ldap);
my $compare_operations = getMonitorDesc("cn=Compare,cn=Operations,cn=Monitor","monitorOpCompleted",$ldap);
my $search_operations = getMonitorDesc("cn=Search,cn=Operations,cn=Monitor","monitorOpCompleted",$ldap);
my $write_waiters = getMonitorDesc("cn=Write,cn=Waiters,cn=Monitor","monitorCounter",$ldap);
my $read_waiters =  getMonitorDesc("cn=Read,cn=Waiters,cn=Monitor","monitorCounter",$ldap);

###############################################
# Print the values to $logfile
###############################################
print (LDAPFILE  "$timestamp $total_connections $bytes_sent $initiated_operations $completed_operations $referrals_sent $entries_sent $bind_operations $unbind_operations $add_operations $delete_operations $modify_operations $compare_operations $search_operations $write_waiters $read_waiters \n");
close(LDAPFILE);
