#!/usr/bin/env python
# Program: check-zone-transfers.py
# Author: Matty < matty91 at gmail dot com >
# Current Version: 1.0
# Last Updated: 01-29-2017
# Version history:
#   1.0 Initial Release
# Purpose: Attempts a zone transfer from each host listed in a zone {} stanza
# License: 
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more detai
# Sample output:
#   $ check-zone-transfers.py named.conf
#   Unable to AXFR zone foo.bar.com from IP 1.2.3.4
#   Unable to connect to IP 4.3.2.1 to retrieve zone gorp.com

import re
import sys
import argparse
import subprocess

DEBUG=0
TIMEOUT="1"

def check_zone_transfers(zones_to_check):
    """
       Perform an AXFR from each IP that we are
       configured to slave the zone from
    """
    error = 0

    for zone in zones_to_check:
        if DEBUG:
            print("Zone %s is slaved from %s" % (zone, zones_to_check[zone]))
        for ip in zones_to_check[zone]:
            dig_command = "dig +time=" + TIMEOUT + " +noall @" + ip + " " + zone + " AXFR"
            cmd_output = subprocess.Popen(dig_command, shell=True, stdout=subprocess.PIPE)
            for line in cmd_output.stdout:
                if "Transfer failed" in line:
                    error = 1
                    print("Unable to AXFR zone %s from IP %s" % (zone, ip))
                elif "no servers could be reached" in line:
                    error = 1
                    print("Unable to connect to IP %s to retrieve zone %s " % (ip, zone))
    return error


def process_zones(zone_files):
    """
        Iterate over one or more zone files and return
        a list of zones and the IPs of the slaves we
        are pulling the zones from

        zone "foo.com" {
        type slave;
        file "slave/foo.com";
        masters { 1.2.3.4; 1.2.3.4; };
        allow-query  { desktop_net;  };
    """
    zone_matrix = {}
    regex_pattern = re.compile("[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")

    if DEBUG:
        print("Processing zone files %s " % zone_files)

    for zone_file in zone_files:
         with open(zone_file, "r") as file_to_process:
             for line in file_to_process:
                 if line.startswith('#'):
                    continue
                 elif "zone" in line:
                     zone_name = line.split("\"")[1]
                 elif "masters" in line:
                     zone_matrix[zone_name] = re.findall(regex_pattern, line)
    return zone_matrix

    
def process_cli():
    """ 
        parses the CLI arguments and returns a list
        of zone files to get slave info from
    """

    parser = argparse.ArgumentParser(description='DNS Zone File Checker')

    parser.add_argument('zonefiles', nargs='*',
                        help="List of zone files to grab slave information from",
                        metavar="Zonefile")
    args = parser.parse_args()

    if not args.zonefiles:
        print("ERROR: No zone files passed on the command line")
        print("Usage: %s zone1 zone2 ..." % sys.argv[0])
        sys.exit(1)

    return args.zonefiles


def main():
    """
       Main execution point
    """
    zone_files = process_cli()
    zone_list = process_zones(zone_files)
    rc = check_zone_transfers(zone_list)
    sys.exit(rc)


if __name__ == "__main__":
    main()
