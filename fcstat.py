#!/usr/bin/env python
#
# Program: FIbre channel statistics utility <fcstat.py>
#
# Author: Matty < matty91 at gmail dot com >
#
# Current Version: 1.0
#
# Revision History:
#
# Last Updated: 07-15-2019
#
# Purpose: Display fibre channel I/O statistics and errors
#
# Example:
#         $ ./fcstat.py
#         HBA         RX Frames   TX Frames   Errors      Invalid CRC  MB/In           MB/Out
#         host1       356886      408365      0           0            683             817
#         host9       358211      201178      0           0            690             802
#         host10      341845      264495      0           0            666             529
#         host11      348006      421530      0           0            672             843
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

import os
import sys
import time
import signal
import collections


def handleSigINT(signalNumber, currentFrame):
    """
       exit gracefully if the user hits cntrl+c
    """
    sys.exit(0)


def initStatistics(hba, stats):
    """
       Initialize the statistics to the current value in /sys
    """
    stats[hba]['rx_frames'] = getStats(hba, stats, "rx_frames")
    stats[hba]['tx_frames'] = getStats(hba, stats, "tx_frames")
    stats[hba]['error_frames'] = getStats(hba, stats, "error_frames")
    stats[hba]['invalid_crc_count'] = getStats(hba, stats, "invalid_crc_count")
    stats[hba]['fcp_input_megabytes'] = getStats(hba, stats,
                                                 "fcp_input_megabytes")
    stats[hba]['fcp_output_megabytes'] = getStats(hba, stats,
                                                  "fcp_output_megabytes")


def getStats(hba, stats, stat):
    """
       Retrieve the requested stat from the /sys directory
    """
    with open("/sys/class/fc_host/" + hba + "/statistics/" + stat) as stat:
        return (int(stat.read(), 16))


def getHBAList():
    """
       Retrieve the list of FC HBAs and return them as a list
    """
    if os.path.isdir("/sys/class/fc_host"):
        return (os.listdir("/sys/class/fc_host/"))


def printHBAheader():
    """
       Header to print
    """
    print("%-10s  %-10s  %-10s  %-10s  %-14s  %-10s  %-10s" %
          ("HBA", "RX Frames", "TX Frames", "Errors", "Invalid CRC", "MB/In",
           "MB/Out"))


def printHBAstats(hba, stats):
    """
       Get the new stat and subtract it from the old one. Then print it.
    """
    print("%-10s  %-10s  %-10s  %-10s  %-14s  %-10s  %-10s" %
          (hba, getStats(hba, stats, "rx_frames") - stats[hba]['rx_frames'],
           getStats(hba, stats, "tx_frames") - stats[hba]['tx_frames'],
           getStats(hba, stats, "error_frames") - stats[hba]['error_frames'],
           getStats(hba, stats, "invalid_crc_count") -
           stats[hba]['invalid_crc_count'],
           getStats(hba, stats, "fcp_input_megabytes") -
           stats[hba]['fcp_input_megabytes'],
           getStats(hba, stats, "fcp_output_megabytes") -
           stats[hba]['fcp_output_megabytes']))


def verifyStatsFilesExist(hba):
    """
       Check to make sure the various statistics files exist
    """
    if (not os.path.isfile("/sys/class/fc_host/" + hba +
                           "/statistics/rx_frames")
            and not os.path.isfile("/sys/class/fc_host/" + hba +
                                   "/statistics/tx_frames")
            and not os.path.isfile("/sys/class/fc_host/" + hba +
                                   "/statistics/error_frames")
            and not os.path.isfile("/sys/class/fc_host/" + hba +
                                   "/statistics/invalid_crc_count")
            and not os.path.isfile("/sys/class/fc_host/" + hba +
                                   "/statistics/fcp_input_megabytes")
            and not os.path.isfile("/sys/class/fc_host/" + hba +
                                   "/statistics/fcp_output_megabytes")):
        print("The statistics directory doesn't exist for HBA " + hba)
        sys.exit(1)


def main():
    """
       Here is where the cheese is made
    """
    hbas = getHBAList()
    stats = collections.defaultdict(dict)

    signal.signal(signal.SIGINT, handleSigINT)

    for hba in getHBAList():
        verifyStatsFilesExist(hba)
        initStatistics(hba, stats)

    while True:
        printHBAheader()
        for hba in getHBAList():
            printHBAstats(hba, stats)
            initStatistics(hba, stats)
        print("\n")
        time.sleep(1)


if __name__ == "__main__":
    main()
