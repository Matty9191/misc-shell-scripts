#!/usr/bin/env python
# Script: strace-combiner.py
# Author: Matty <matty91@gmail.com>
# Date: 10-11-2016
# Purpose:
#   This script takes strace output like the following:
#         close(255 <unfinished ...>
#           .....................
#         <... close resumed> )       = 0
#   And prints out he following:
#         close(255)       = 0
#   I wrote this so I didn't have to constantly bounce back
#   and forth between unfinished and resumed blocks. The
#   time savings add up when you are reviewing a large
#   amount of strace data.
# License: 
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.

import re
import sys

def process_strace_input():
    """
       Processes each line of strace data and reassembled the lines
       Sample input:
          close(255 <unfinished ...>
          <... rt_sigprocmask resumed> NULL, 8) = 0
          <... close resumed> )       = 0
          [pid 19199] close(255 <unfinished ...>
          [pid 19198] <... rt_sigprocmask resumed> NULL, 8) = 0
          [pid 19199] <... close resumed> )       = 0
    """
    pid = syscall = ""
    holding_cell = list()

    if len(sys.argv) > 1:
        strace_file =  open(sys.argv[1], "r")
    else:
        strace_file = sys.stdin

    for line in strace_file.read().splitlines():
        if "clone" in line:
            print line
        if "unfinished" in line:
            holding_cell.append(line.split("<")[0])
        elif "resumed" in line:
            # Get the name of the system call so we  can try 
            # to match this line w/ one in the buffer
            identifier = line.split()[1]
            for cell in holding_cell:
                if identifier in cell:
                    print cell + line.split(">")[1]
                    holding_cell.remove(cell)
        else:
            print line
            
    strace_file.close()
            

def main():
    """
       Main function used for testing
    """
    process_strace_input()


if __name__ == "__main__":
    main()
