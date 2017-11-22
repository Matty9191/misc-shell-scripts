#!/usr/bin/ksh
#
# Program: DTrace NFS Operation Tracer <nfstrace>
#
# Author: Matty < matty91 at gmail dot com >
#
# Current Version: 1.0
#
# Revision History:
#  Version 1.0
#
# Last Updated: 05-03-2006
#
# Purpose: Traces NFS operations by process id, process name or
#          system wide. For operations that support client-side
#          caching, the word "physical" or "logical is displayed
#          to indicate the type of operation.
#
# Installation:
#   Copy the shell script to a suitable location
#
# Notes: The code to process command line arguments was borrowed 
#        from Brendan Gregg's rwsnoop script (part of the DTraceToolkit). 
#
# Acknowledgements: I would like to thank Spencer Shepler for his 
#                   awesome feedback.
#
# CDDL HEADER START
#  The contents of this file are subject to the terms of the
#  Common Development and Distribution License, Version 1.0 only
#  (the "License").  You may not use this file except in compliance
#  with the License.
#
#  You can obtain a copy of the license at Docs/cddl1.txt
#  or http://www.opensolaris.org/os/licensing.
#  See the License for the specific language governing permissions
#  and limitations under the License.
# CDDL HEADER END
#
# Example:
# $ nfstrace
# Executable Operation    Type     Time    Size   Path
# mkdir      nfs3_lookup  physical 359953  N/A    /opt/nfs/htdocs/test
# mkdir      nfs3_getattr logical  17481   N/A    /opt/nfs/htdocs/test
# mkdir      nfs3_getattr logical  7577    N/A    /opt/nfs/htdocs/test
# mkdir      nfs3_mkdir   physical 843500  N/A    /opt/nfs/htdocs/test/test
# rmdir      nfs3_access  logical  19772   N/A    /opt/nfs/htdocs/test
# rmdir      nfs3_lookup  logical  69222   N/A    /opt/nfs/htdocs/test/test
# rmdir      nfs3_access  logical  7744    N/A    /opt/nfs/htdocs/test
# rmdir      nfs3_rmdir   physical 1390474 N/A    /opt/nfs/htdocs/test/test
# touch      nfs3_access  logical  19566   N/A    /opt/nfs/htdocs/test
# touch      nfs3_lookup  logical  68824   N/A    /opt/nfs/htdocs/test/1
# touch      nfs3_getattr logical  17842   N/A    /opt/nfs/htdocs/test/1
# touch      nfs3_access  logical  7746    N/A    /opt/nfs/htdocs/test
# touch      nfs3_lookup  logical  26527   N/A    /opt/nfs/htdocs/test/1
# touch      nfs3_setattr logical  597203  N/A    /opt/nfs/htdocs/test/1
# ln         nfs3_lookup  physical 299999  N/A    /opt/nfs/htdocs/test/2
# ln         nfs3_access  physical 20033   N/A    /opt/nfs/htdocs/test
# ln         nfs3_lookup  physical 222977  N/A    /opt/nfs/htdocs/test/2
# ln         nfs3_access  physical 9553    N/A    /opt/nfs/htdocs/test
# ln         nfs3_lookup  physical 222109  N/A    /opt/nfs/htdocs/test/2
# ln         nfs3_symlink physical 899939  N/A    /opt/nfs/htdocs/test/2 -> /opt/nfs/htdocs/test1
# cat        nfs3_access  logical  19528   N/A    /opt/nfs/htdocs/test
# cat        nfs3_lookup  logical  67471   N/A    /opt/nfs/htdocs/test/2
# cat        nfs3_access  logical  7722    N/A    /opt/nfs/htdocs/test
# cat        nfs3_lookup  logical  26941   N/A    /opt/nfs/htdocs/test/1
# cat        nfs3_access  physical 278486  N/A    /opt/nfs/htdocs/test/1
# cat        nfs3_getattr logical  17554   N/A    /opt/nfs/htdocs/test/1
# cat        nfs3_read    logical  54848   8192   /opt/nfs/htdocs/test/1
# cat        nfs3_read    logical  10082   8192   /opt/nfs/htdocs/test/1
# bash       nfs3_access  logical  19707   N/A    /opt/nfs/htdocs/test
# bash       nfs3_lookup  logical  66602   N/A    /opt/nfs/htdocs/test/.
# bash       nfs3_access  logical  7740    N/A    /opt/nfs/htdocs/test
# cp         nfs3_write   physical 38821   3935   /opt/nfs/htdocs/test/99

opt_name=0
opt_filter=0
opt_pid=0
PID=0
NAME=""

while getopts bp:n: name
do
        case $name in
        b)      opt_physical=1
                ;;

        n)      opt_name=1; NAME=$OPTARG
                ;;

        p)      opt_pid=1; PID=$OPTARG
                ;;

        h|?)    echo "
                USAGE: $0 [-p pid] [-n name] [-d]
                           -d     # Print physical operations
                           -n     # Filter by processes with the name 'name'
                           -p     # Filter by processes with the pid 'pid'
                END"
                exit 1
                ;;
        esac
done

shift $(( $OPTIND - 1 ))

if (( opt_name || opt_pid ))
then
        opt_filter=1
fi

/usr/sbin/dtrace -n '

#pragma D option quiet
#pragma D option bufsize=4m
#pragma D option switchrate=10hz

inline int OPT_name = '$opt_name';
inline int OPT_pid  = '$opt_pid';
inline int FILTER   = '$opt_filter';
inline int PID      = '$PID';
inline string NAME  = "'$NAME'";

dtrace:::BEGIN
{
      printf("%-10s %-12s %-8s %-7s %-6s %-35s\n", "Executable",
                                                   "Operation",
                                                   "Type",
                                                   "Time",
                                                   "Size",
                                                   "Path");
}

/*
*   Function: rfs3call
*
*   Notes: Sensor to determine if a network call was made.
*
*/
fbt:nfs:rfs3call:entry
{
   self->netread = 1;
}


/*
*  Function: nfs3_read: VFS operation registered to handle NFS reads.
*
*  Notes: nfs3_read is the high-level VFS function, and will
*  call nfsgetapage to fault in a page. This will in turn cause 
*  nfs3read() to be executed, as evidenced in the following stack 
*  trace:
*
*    nfs3read:entry
*    nfs`nfs3_bio+0x296
*    nfs`nfs3_getapage+0x3ea
*    nfs`nfs3_getpage+0x197
*    genunix`fop_getpage+0x2d
*    genunix`segvn_fault+0x76f
*    genunix`as_fault+0x3c8
*    unix`pagefault+0x7e
*    unix`trap+0xf21
*    unix`_cmntrap+0x83
*    unix`kcopy+0x25
*    genunix`uiomove+0x9c
*    genunix`strmakedata+0x101
*    genunix`strput+0xb4
*    genunix`strwrite+0x151
*    specfs`spec_write+0x4e
*    genunix`fop_write+0x1b
*    genunix`write+0x29a
*    unix`sys_sysenter+0xdc
*
*/

fbt:nfs:nfs3_read:entry
{
    self->readts   = timestamp;
    self->readfile =  args[0]->v_path;
    self->requestsize = args[1]->uio_resid;
    self->netread = 0;

    /* default is to trace unless filtering, */
    self->ok = FILTER ? 0 : 1;

    /* check each filter, */
    (OPT_name == 1 && NAME == execname) ? self->ok = 1 : 1;
    (OPT_pid == 1 && PID == pid) ? self->ok = 1 : 1;
}

fbt:nfs:nfs3_read:return
/ self->readts && !self->netread && self->ok/
{
    printf("%-10s %-12s %-8s %-7d %-6d %-35s\n", execname,
                                            probefunc,
                                            "logical",
                                            timestamp - self->readts,
                                            self->requestsize,
                                            stringof(self->readfile));
}

fbt:nfs:nfs3_read:return
/ self->readts && self->netread  && self->ok/
{
    printf("%-10s %-12s %-8s %-7d %-6d %-35s\n", execname,
                                            probefunc,
                                            "physical",
                                            timestamp - self->readts,
                                            self->requestsize,
                                            stringof(self->readfile));
}

fbt:nfs:nfs3read:entry
{
    self->netread = 1;
}


/*
*  Function: nfs3_write: VFS operation registered to handle NFS writes.
*
*  Notes: write to files that reside on NFS server are performed
*  asyncronously, unless blocking I/O occurs.
*/

fbt:nfs:nfs3_write:entry
{
    self->writets = timestamp;
    self->writefile = args[0]->v_path;
    self->requestsize = ((struct uio *)arg1)->uio_resid;

    /* default is to trace unless filtering, */
    self->ok = FILTER ? 0 : 1;

    /* check each filter, */
    (OPT_name == 1 && NAME == execname) ? self->ok = 1 : 1;
    (OPT_pid == 1 && PID == pid) ? self->ok = 1 : 1;
}

fbt:nfs:nfs3_write:return
/self->writets && self->ok/
{
    printf("%-10s %-12s %-8s %-7d %-6d %-35s\n", execname,
                                            probefunc,
                                            "physical",
                                            timestamp - self->writets,
                                            self->requestsize,
                                            stringof(self->writefile));
}


/*
*   Function: nfs3_readdir implements the NFSv3 readdir VOP function
*/
fbt:nfs:nfs3_readdir:entry
{
    self->readdirts = timestamp;
    self->readdir = args[0]->v_path;
    self->netread = 0;

    /* default is to trace unless filtering, */
    self->ok = FILTER ? 0 : 1;

    /* check each filter, */
    (OPT_name == 1 && NAME == execname) ? self->ok = 1 : 1;
    (OPT_pid == 1 && PID == pid) ? self->ok = 1 : 1;
}

fbt:nfs:nfs3_readdir:return
/ self->readdirts && !self->netread && self->ok /
{
    printf("%-10s %-12s %-8s %-7d %-6s %-35s\n", execname,
                                            probefunc,
                                            "logical",
                                            timestamp - self->readdirts,
                                            "N/A",
                                            stringof(self->readdir));
}

fbt:nfs:nfs3_readdir:return
/ self->readdirts && self->netread && self->ok /
{
    printf("%-10s %-12s %-8s %-7d %-6s %-35s\n", execname,
                                            probefunc,
                                            "physical",
                                            timestamp - self->readdirts,
                                            "N/A",
                                            stringof(self->readdir));
}


/*
* Function: nfs3_getattr implements the NFSv3 getattr VOP function
*
*/
fbt:nfs:nfs3_getattr:entry
{
    self->getattrts = timestamp;
    self->getattr =  args[0]->v_path;
    self->netread = 0;

    /* default is to trace unless filtering, */
    self->ok = FILTER ? 0 : 1;

    /* check each filter, */
    (OPT_name == 1 && NAME == execname) ? self->ok = 1 : 1;
    (OPT_pid == 1 && PID == pid) ? self->ok = 1 : 1;
}

fbt:nfs:nfs3_getattr:return
/ self->getattrts && !self->netread && self->ok /
{
    printf("%-10s %-12s %-8s %-7d %-6s %-35s\n", execname,
                                            probefunc,
                                            "logical",
                                            timestamp - self->getattrts,
                                            "N/A",
                                            stringof(self->getattr));
}

fbt:nfs:nfs3_getattr:return
/ self->getattrts && self->netread && self->ok /
{
    printf("%-10s %-12s %-8s %-7d %-6s %-35s\n", execname,
                                            probefunc,
                                            "physical",
                                            timestamp - self->getattrts,
                                            "N/A",
                                            stringof(self->getattr));
}


/*
*  Function: nfs3_setattr implements the NFSv3 setattr VOP function
*/
fbt:nfs:nfs3_setattr:entry
{
    self->setattrts   = timestamp;
    self->setattr =  args[0]->v_path;
    self->netread = 0;

    /* default is to trace unless filtering, */
    self->ok = FILTER ? 0 : 1;

    /* check each filter, */
    (OPT_name == 1 && NAME == execname) ? self->ok = 1 : 1;
    (OPT_pid == 1 && PID == pid) ? self->ok = 1 : 1;
}

fbt:nfs:nfs3_setattr:return
/ self->setattrts && self->ok /
{
    printf("%-10s %-12s %-8s %-7d %-6s %-35s\n", execname,
                                            probefunc,
                                            "logical",
                                            timestamp - self->setattrts,
                                            "N/A",
                                            stringof(self->setattr));
}


/*
*  Function: nfs3_lookup implements the lookup VOP interface
*
*/
fbt:nfs:nfs3_lookup:entry
{
    self->lookupts   = timestamp;
    self->lookupdir =  args[0]->v_path;
    self->lookupfile = arg1;
    self->netread = 0;

    /* default is to trace unless filtering, */
    self->ok = FILTER ? 0 : 1;

    /* check each filter, */
    (OPT_name == 1 && NAME == execname) ? self->ok = 1 : 1;
    (OPT_pid == 1 && PID == pid) ? self->ok = 1 : 1;
}

fbt:nfs:nfs3_lookup:return
/ self->lookupts && !self->netread && self->ok /
{
    this->join = strjoin(stringof(self->lookupdir), "/");
    this->join1 = strjoin(this->join,stringof(self->lookupfile));

    printf("%-10s %-12s %-8s %-7d %-6s %-35s\n", execname,
                                            probefunc,
                                            "logical",
                                            timestamp - self->lookupts,
                                            "N/A",
                                            this->join1);
}

fbt:nfs:nfs3_lookup:return
/ self->lookupts && self->netread && self->ok /
{
    this->join = strjoin(stringof(self->lookupdir), "/");
    this->join1 = strjoin(this->join,stringof(self->lookupfile));

    printf("%-10s %-12s %-8s %-7d %-6s %-35s\n", execname,
                                            probefunc,
                                            "physical",
                                            timestamp - self->lookupts,
                                            "N/A",
                                            this->join1);
}


/*
*  Function: nfs3_access implements the access VOP interface
*
*/
fbt:nfs:nfs3_access:entry
{
    self->accessts   = timestamp;
    self->access =  args[0]->v_path;

    /* default is to trace unless filtering, */
    self->ok = FILTER ? 0 : 1;

    /* check each filter, */
    (OPT_name == 1 && NAME == execname) ? self->ok = 1 : 1;
    (OPT_pid == 1 && PID == pid) ? self->ok = 1 : 1;
}

fbt:nfs:nfs3_access:return
/ self->accessts && !self->netread && self->ok /
{
    printf("%-10s %-12s %-8s %-7d %-6s %-35s\n", execname,
                                            probefunc,
                                            "logical",
                                            timestamp - self->accessts,
                                            "N/A",
                                            stringof(self->access));
}

fbt:nfs:nfs3_access:return
/ self->accessts && self->netread && self->ok /
{
    printf("%-10s %-12s %-8s %-7d %-6s %-35s\n", execname,
                                            probefunc,
                                            "physical",
                                            timestamp - self->accessts,
                                            "N/A",
                                            stringof(self->access));
}


/*
*  Function: nfs3_create implements the access VOP interface
*
*/
fbt:nfs:nfs3_create:entry
{
    self->createts   = timestamp;
    self->create =  args[0]->v_path;

    /* default is to trace unless filtering, */
    self->ok = FILTER ? 0 : 1;

    /* check each filter, */
    (OPT_name == 1 && NAME == execname) ? self->ok = 1 : 1;
    (OPT_pid == 1 && PID == pid) ? self->ok = 1 : 1;
}

fbt:nfs:nfs3_create:return
/ self->createts && self->ok /
{
    printf("%-10s %-12s %-8s %-7d %-6s %-35s\n", execname,
                                            probefunc,
                                            "physical",
                                            timestamp - self->createts,
                                            "N/A",
                                            stringof(self->create));
}


/*
*  Function: nfs3_remove implements the access VOP interface
*
*/
fbt:nfs:nfs3_remove:entry
{
    self->removets = timestamp;
    self->remove = args[0]->v_path;

    /* default is to trace unless filtering, */
    self->ok = FILTER ? 0 : 1;

    /* check each filter, */
    (OPT_name == 1 && NAME == execname) ? self->ok = 1 : 1;
    (OPT_pid == 1 && PID == pid) ? self->ok = 1 : 1;
}

fbt:nfs:nfs3_remove:return
/ self->removets && self->ok /
{
    printf("%-10s %-12s %-8s %-7d %-6s %-35s\n", execname,
                                            probefunc,
                                            "physical",
                                            timestamp - self->removets,
                                            "N/A",
                                            stringof(self->remove));
}


/*
*  Function: nfs3_rename implements the access VOP interface
*
*/
fbt:nfs:nfs3_rename:entry
{
     self->renamets = timestamp;
     self->renameold = arg1;
     self->renamenew = arg3;

    /* default is to trace unless filtering, */
    self->ok = FILTER ? 0 : 1;

    /* check each filter, */
    (OPT_name == 1 && NAME == execname) ? self->ok = 1 : 1;
    (OPT_pid == 1 && PID == pid) ? self->ok = 1 : 1;
}

fbt:nfs:nfs3_rename:return
/ self->renamets && self->ok /
{
    this->joined = strjoin(stringof(self->renameold), "->");
    this->joined1 = strjoin(this->joined, stringof(self->renamenew));

    printf("%-10s %-12s %-8s %-7d %-6s %-35s\n", execname,
                                            probefunc,
                                            "physical",
                                            timestamp - self->renamets,
                                            "N/A",
                                            this->joined1);
}


/*
*  Function: nfs3_mkdir implements the access VOP interface
*
*/
fbt:nfs:nfs3_mkdir:entry
{
     self->mkdirts = timestamp;
     self->mkdir = args[0]->v_path;
     self->mkdirentry = arg1;

     /* default is to trace unless filtering, */
     self->ok = FILTER ? 0 : 1;

     /* check each filter, */
     (OPT_name == 1 && NAME == execname) ? self->ok = 1 : 1;
     (OPT_pid == 1 && PID == pid) ? self->ok = 1 : 1;
}

fbt:nfs:nfs3_mkdir:return
/ self->mkdirts && self->ok /
{
    this->join1 = strjoin(stringof(self->mkdir), "/");
    this->join2 = strjoin(this->join1, stringof(self->mkdirentry));

    printf("%-10s %-12s %-8s %-7d %-6s %-35s\n", execname,
                                            probefunc,
                                            "physical",
                                            timestamp - self->mkdirts,
                                            "N/A",
                                            this->join2);
}


/*
*  Function: nfs3_rmdir implements the access VOP interface
*
*/
fbt:nfs:nfs3_rmdir:entry
{
     self->rmdirts = timestamp;
     self->rmdir   = args[0]->v_path;
     self->rmdirentry = arg1;

    /* default is to trace unless filtering, */
    self->ok = FILTER ? 0 : 1;

    /* check each filter, */
    (OPT_name == 1 && NAME == execname) ? self->ok = 1 : 1;
    (OPT_pid == 1 && PID == pid) ? self->ok = 1 : 1;
}

fbt:nfs:nfs3_rmdir:return
/ self->rmdirts && self->ok /
{
    this->join1 = strjoin(stringof(self->rmdir), "/");
    this->join2 = strjoin(this->join1, stringof(self->rmdirentry));

    printf("%-10s %-12s %-8s %-7d %-6s %-35s\n", execname,
                                            probefunc,
                                            "physical",
                                            timestamp - self->rmdirts,
                                            "N/A",
                                            this->join2);
}


/*
*  Function: nfs3_symlink implements the access VOP interface
*
*/
fbt:nfs:nfs3_symlink:entry
{
     self->symlinkts = timestamp;
     self->linkdir = args[0]->v_path;
     self->symlinkfrom = arg1;
     self->symlinkto = arg3;

    /* default is to trace unless filtering, */
    self->ok = FILTER ? 0 : 1;

    /* check each filter, */
    (OPT_name == 1 && NAME == execname) ? self->ok = 1 : 1;
    (OPT_pid == 1 && PID == pid) ? self->ok = 1 : 1;
}

fbt:nfs:nfs3_symlink:return
/ self->symlinkts && self->ok /
{
    this->dir = stringof(self->linkdir);
    this->join1 = strjoin(this->dir,"/");
    this->join2 = strjoin(this->join1, stringof(self->symlinkfrom));
    this->join3 = strjoin(this->join2, " -> ");
    this->join4 = strjoin(this->join3, this->dir);
    this->join5 = strjoin(this->join4, "/");
    this->join6 = strjoin(this->join5, stringof(self->symlinkto));

    printf("%-10s %-12s %-8s %-7d %-6s %-35s\n", execname,
                                            probefunc,
                                            "physical",
                                            timestamp - self->symlinkts,
                                            "N/A",
                                            this->join6);
}


/*
*  Function: nfs3_readlink implements the access VOP interface
*
*/
fbt:nfs:nfs3_readlink:entry
{
     self->readlinkts = timestamp;
     self->readlink = args[0]->v_path;

    /* default is to trace unless filtering, */
    self->ok = FILTER ? 0 : 1;

    /* check each filter, */
    (OPT_name == 1 && NAME == execname) ? self->ok = 1 : 1;
    (OPT_pid == 1 && PID == pid) ? self->ok = 1 : 1;
}

fbt:nfs:nfs3_readlink:return
/ self->readlinkts && !self->netread && self->ok /
{
    printf("%-10s %-12s %-8s %-7d %-6s %-35s\n", execname,
                                            probefunc,
                                            "logical",
                                            timestamp - self->symlinkts,
                                            "N/A",
                                            stringof(self->readlink));
}

fbt:nfs:nfs3_readlink:return
/ self->readlinkts && self->netread && self->ok /
{
    printf("%-10s %-12s %-8s %-7d %-6s %-35s\n", execname,
                                            probefunc,
                                            "physical",
                                            timestamp - self->symlinkts,
                                            "N/A",
                                            stringof(self->readlink));
}'
