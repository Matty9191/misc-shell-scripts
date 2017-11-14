#!/usr/bin/perl
#
# Program: mod_deflate statistics utility <deflate-stats.pl>
#
# Author: Matty < matty91 at gmail dot com >
#
# Current Version: 1.0
#
# Revision History:
#   Version 1.0
#     - Original release
#
# Last Updated: 12-23-2005
#
# License: 
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Purpose:
#   Provides statistical data from mod_deflate logfiles
#
# Example:
#   $ deflate-stats.pl /var/tmp/apache/logs/deflate_log 
#
#   Processed logfile /var/tmp/apache/logs/deflate_log
#
#      Total number of HTTP requests          : 173980
#      Total number of HTTP requests deflated : 146557
#      Total output bytes by mod_deflate      : 314.69 Megabytes
#      Total input bytes to mod_deflate       : 13.56 Gigabytes
#      Total bandwidth saved by mod_deflate   : 13.26 Gigabytes (97%)
#  
#      Average request size                   : 97.05 Kilobytes
#      Average # bytes saved per request      : 94.85 Kilobytes
#  
#   Requests  Total Bytes Requested  Bytes Actually Sent   Ratio  URI                                     
#   90552     13.32 Gigabytes        285.58 Megabytes      97     /nada.html                              
#   28007     41.24 Megabytes        13.46 Megabytes       67     /doc.txt                                
#   27998     206.13 Megabytes       15.65 Megabytes       92     /feedback.txt         
#
# Miscellaneous:
#  To use this script, mod_deflate needs to be enabled in the httpd.conf. The 
#  following entries were used while testing this script:
#
#  # Load the deflate Apache modules
#  LoadModule deflate_module modules/mod_deflate.so
#
#  # utilize mod_deflate for Content-Type == text/(html|plain|xml)
#  # This may break older browsers
#  AddOutputFilterByType DEFLATE text/html text/plain text/xml
#
#  # Tell mod_deflate to add notes to r->notes table
#  DeflateFilterNote Input instream
#  DeflateFilterNote Output outstream
#  DeflateFilterNote Ratio ratio
#
#  #  Create a custom logfile format and log to deflate_log
#  LogFormat "%r %{outstream}n %{instream}n %{ratio}n" deflate
#  CustomLog logs/deflate_log deflate

$kb = 1024;
$mb = 1024 * 1024;
$gb = 1024 * 1024 * 1024;
$tb = 1024 * 1024 * 1024 * 1024;
$pb = 1024 * 1024 * 1024 * 1024 * 1024;

if ( @ARGV <  1) {
     print "Usage: deflate-stats.pl <logfile1> <logfile2> <...>\n";
     exit(1);
}

foreach $logfile (@ARGV) {

     # Set to zero in case we come around a second time 
     my $requests = 0;
     my $total_uncompressed_bytes = 0;
     my $total_compressed_bytes = 0;

     open(LOG, $logfile) || print "Cannot open logfile $logfile\n";
 
     while ( $line = <LOG> ) {

        $requests++;

        # Format of line: GET /favicon.ico HTTP/1.1 226 292 77
        ($method, $uri, $protocol, $cbytes, $bytes, $ratio) = split(' ', $line);

        if ($bytes =~ /^[0-9]+/) {
             $total_deflated++;
             $total_compressed_bytes += $cbytes;
             $total_uncompressed_bytes += $bytes;
           
             $uris{$uri}{TOTAL}++; 
             $uris{$uri}{COMPRESSED} += $cbytes;
             $uris{$uri}{UNCOMPRESSED} += $bytes;
        }
    }

    # Perform the calculations here to make things easier to read
    $average_request_size = $total_uncompressed_bytes / $total_deflated;
    $bytes_not_sent = $total_uncompressed_bytes - $total_compressed_bytes;
    $compression_ratio = 100 - $total_compressed_bytes / $total_uncompressed_bytes * 100;

    # Use several print statements to make things easier to read
    print "Processed logfile $logfile\n\n";
    printf("Total number of HTTP requests          : %d\n", $requests);
    printf("Total number of HTTP requests deflated : %d\n", $total_deflated);
    printf("Total output bytes by mod_deflate      : %s\n", convert($total_compressed_bytes));
    printf("Total input bytes to mod_deflate       : %s\n", convert($total_uncompressed_bytes));
    printf("Total bandwidth saved by mod_deflate   : %s (%d%%)\n\n", convert($bytes_not_sent), $compression_ratio);

    printf("Average request size                   : %s\n", &convert($average_request_size));
    printf("Average # bytes saved per request      : %s\n\n", &convert($bytes_not_sent / $total_deflated));

    printf("%-8s  %-21s  %-20s  %-5s  %-40s\n", "Requests", "Total Bytes Requested",  "Bytes Actually Sent", "Ratio", "URI");
  
    @sarray = sort { $uris{$b}{TOTAL} <=> $uris{$a}{TOTAL} } keys %uris;
    for ( $i = 0; ( ( $i < 10) && ( $i < @sarray)); $i++ ) {
        printf("%-8d  %-21s  %-20s  %-5d  %-40s\n", $uris{$sarray[$i]}{TOTAL},
                                           convert($uris{$sarray[$i]}{UNCOMPRESSED}),
                                           convert($uris{$sarray[$i]}{COMPRESSED}),
                                           100 - $uris{$sarray[$i]}{COMPRESSED} / $uris{$sarray[$i]}{UNCOMPRESSED} * 100,
                                           $sarray[$i]);
    }

    print "\n";
    close(LOG);
}

# Sub-routine name: convert()
# Arguments:
#   arg1 -> The value to covnert to MB -> PB
sub convert()
{
    # Return the number of bytes
    if ( $_[0] < $kb ) {
       return sprintf("%d Bytes", $_[0]);

    # Return the number of kilobytes
    } elsif ( $_[0] < $mb ) {
       return sprintf("%.2f Kilobytes", $_[0] / $kb);

    # Return the number of megabytes
    } elsif ( $_[0] < $gb ) {
       return sprintf("%.2f Megabytes", $_[0] / $mb);

    # Return teh number of gigabytes
    } elsif ( $_[0] < $tb ) {
       return sprintf("%.2f Gigabytes", $_[0] / $gb);

    # Return the number of terabytes
    } elsif ( $_[0] < $pb ) {
       return sprintf("%.2f Terabytes", $_[0] / $tb);
   
    # Yikes -- this is a lot! 
    } else {
       return $_[0] . "a lot";
   }
}
