#!/usr/bin/perl -t -w
#
# Program: File stat <stat.pl>
#
# Author: Matty < matty91 at gmail dot com >
#
# Current Version: 1.0
#
# Revision History:
#
# Version 1.1
#     - Changed uid to gid -- Michael Bracewell 	
#
# Version 1.0
#     Original release
#
# Last Updated: 09-13-2005
#
# Examples
#  $ stat.pl /etc/services /etc/passwd /etc/shadow
#  
#    File: /etc/services
#    Size: 15           Blocks: 2                Block Size: 8192
#  Device: 22282240     Inode: 7876              Links:    1
#   Perms: 777          Uid: ( 0 / root )        Gid: ( 0 / root )       
#  Access Time (mtime)      : Tue Sep 13 18:48:34 2005 
#  Change Time (ctime)      : Mon Aug 15 22:48:37 2005 
#  Modification Time (mtime): Mon Aug 15 22:48:37 2005 
#
#    File: /etc/passwd
#    Size: 725          Blocks: 2                Block Size: 8192
#  Device: 22282240     Inode: 9021              Links:    1
#   Perms: 644          Uid: ( 0 / root )        Gid: ( 0 / root )       
#  Access Time (mtime)      : Tue Sep 13 18:50:51 2005 
#  Change Time (ctime)      : Tue Aug 16 00:25:09 2005 
#  Modification Time (mtime): Tue Aug 16 00:25:09 2005 
#
#    File: /etc/shadow
#    Size: 376          Blocks: 2                Block Size: 8192
#  Device: 22282240     Inode: 10176             Links:    1
#   Perms: 400          Uid: ( 0 / root )        Gid: ( 0 / root )       
#  Access Time (mtime)      : Tue Sep 13 18:50:51 2005 
#  Change Time (ctime)      : Tue Aug 16 00:25:18 2005 
#  Modification Time (mtime): Tue Aug 16 00:25:18 2005 

# Load modules
use Getopt::Std;

# Create a universal usage routine to call if problems are detected
sub usage () {
        printf("Usage: stat.pl <file1> ... <fileN>\n");
}

# Make sure at least one file was passed on the command line
if ( ! @ARGV ) {
        usage();
        exit(1);
}

# For each file passed on the command line, lstat it
foreach $file (@ARGV) {

       my ($dev,$inode, $mode, $nlink, $uid, $gid, $rdev, $size,
        $atime, $mtime, $ctime, $blksize, $blocks) = lstat($file);

        printf("\n  File: $file\n");
        printf("  Size: %-12s Blocks: %-12s     Block Size:%-5s\n",$size, $blocks, $blksize);
        printf("Device: %-12s Inode: %-12s      Links: %-4s\n", $dev, $inode, $nlink);

        $uid_string = "( $uid / " .  getpwuid($uid) . " )";
        $gid_string = "( $gid / " .  getgrgid($gid) . " )";

        printf(" Perms: %-12o Uid: %-19s Gid: %-19s\n", $mode & 07777, $uid_string, $gid_string);
        printf("Access Time (mtime)      : %-25s\n", scalar localtime $atime);
        printf("Change Time (ctime)      : %-25s\n", scalar localtime $ctime);
        printf("Modification Time (mtime): %-25s\n\n", scalar localtime $mtime);
}
