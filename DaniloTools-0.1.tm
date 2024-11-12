#
# Danilo' Tcl Tools Package
#
# (C) Danilo Chang 2017, MIT License
#

package require Tcl 8.6-
package require TclOO
package require sha256

package provide DaniloTools 0.1

#
# Wrapper for function call
#
proc funcall {function args} {
    try {
        set result [info commands $function]

        if {[string equal $result {}]} {
            set result2 [info procs $function]

            if {[string equal $result2 {}]} {
                tailcall apply $function {*}$args
            } else {
                tailcall $function {*}$args
            }
        } else {
            tailcall $function {*}$args
        }
    } on error {result options} {
        return -options $options $result
    }
}

#
# Check support thread or not
#
proc is_threaded {} {
  # Tcl 9 always thread-enabled
  if {[package vsatisfies [package provide Tcl] 9.0-]} {
    return 1
  } else {
    return [expr {[info exists ::tcl_platform(threaded)] && $::tcl_platform(threaded)}]
  }
}

#
# Input and output for open command pipeline
#
oo::class create PipeCommand {
    variable command
    variable options
    variable rderr
    variable wrerr
    variable stdio
    variable state
    variable buffer

    constructor {COMMAND args} {
        set command $COMMAND
        set options $args
        lassign [chan pipe] rderr wrerr
        set stdio [open |[concat $command {*}$options [list 2>@ $wrerr]] a+]
        fconfigure $stdio -blocking 0
        close $wrerr

        set buffer ""
        set state 0
    }

    destructor {
        close $rderr
        catch {close $stdio}
    }

    method checkread {} {
        fileevent $stdio readable {}
        set [namespace current]::state 1
    }

    method readOutput {} {
        fileevent $stdio readable "[self] checkread"

        set buffer ""
        set buffer [chan read $stdio]

        return $buffer
    }

    method writeInput {DATA} {
        chan puts -nonewline $stdio $DATA
        chan flush $stdio
    }
}


#
# package uname - using uname to get system information
#
namespace eval uname {
    proc getKernelName {} {
        set mychannel [open "|/usr/bin/uname -s"]
        set name [chan gets $mychannel]
        chan close $mychannel

        return $name
    }

    proc getNodeName {} {
        set mychannel [open "|/usr/bin/uname -n"]
        set name [chan gets $mychannel]
        chan close $mychannel

        return $name
    }

    proc getRelease {} {
        set mychannel [open "|/usr/bin/uname -r"]
        set name [chan gets $mychannel]
        chan close $mychannel

        return $name
    }

    proc getVersion {} {
        set mychannel [open "|/usr/bin/uname -v"]
        set name [chan gets $mychannel]
        chan close $mychannel

        return $name
    }

    proc getMachine {} {
        set mychannel [open "|/usr/bin/uname -m"]
        set name [chan gets $mychannel]
        chan close $mychannel

        return $name
    }

    proc getOperatingSystem {} {
        set mychannel [open "|/usr/bin/uname -o"]
        set name [chan gets $mychannel]
        chan close $mychannel

        return $name
    }
}


#
# Handle a .tar.gz file (decompress)
#
proc untargzipfile {file {dir ""}} {
    variable useArchive

    set useArchive 1
    if {[catch {package require archive} errMsg] == 1} {
        set useArchive 0

        # fallback
        if {[catch {package require zlib} errMsg] == 1} {
            return -code error $errMsg
        }

        if {[catch {package require tar} errMsg] == 1} {
            return -code error $errMsg
        }
    }

    if {[file exists $file] != 1} {
        return -code error "File not exist!!!"
    }

    set rootname [file rootname $file]
    if {[string length $dir] == 0} {
        set dir [file dirname $rootname]
    }

    if {[file exists $dir] != 1} {
        return -code error "Dir not exist!!!"
    }

    if {$useArchive == 1} {
        ::archive::extract $file gzip tar 1 -path $dir
    } else {
        set fout [open $rootname wb]
        chan configure $fout -encoding iso8859-1 -translation binary -buffering none
        set fin [open $file rb]
        chan configure $fin -encoding iso8859-1 -translation binary -buffering none
        zlib push gunzip $fin

        fcopy $fin $fout
        close $fin
        close $fout

        ::tar::untar $rootname -dir $dir

        # Remove the tar file
        file delete $rootname
    }
}

#
# Compress to a .tar.gz file
#
proc targzipfile {path {filename ""}} {
    if {[catch {package require zlib} errMsg] == 1} {
        return -code error $errMsg
    }

    if {[catch {package require tar} errMsg] == 1} {
        return -code error $errMsg
    }

    if {[file exists $path] == 0} {
        return -code error "$path not exist!!!"
    }

    set currentFolder [pwd]
    set dirlist [file split $path]
    set length [llength $dirlist]
    if {[string length $filename] == 0} {
        if {[file isfile $path] == 1} {
            set filename [file tail $path]
        } else {
            if {$length > 1} {
                set filename [lindex $dirlist $length-1]
            } else {
                set filename [lindex $dirlist 0]
            }
        }
    }

    # create a .tar file
    if {$length >= 2} {
        set dirpath [file join {*}[lrange $dirlist 0 $length-2]]
        if {[file isdirectory $dirpath] == 1} {
            cd $dirpath
        }
    }
    ::tar::create $filename.tar $filename

    set filesize [file size $filename.tar]
    set fin [open $filename.tar r]
    chan configure $fin -encoding binary -translation binary -blocking 0
    set fout [open $filename.tar.gz wb]
    chan configure $fout -encoding binary -translation binary -buffering none
    zlib push gzip $fout -level 9

    chan copy $fin $fout -size $filesize
    chan close $fout
    chan close $fin

    # Remove the .tar file
    file delete $filename.tar

    # Back to last folder
    cd $currentFolder
}

#
# Get Tcl module list from ::tcl::tm::path list paths
#
proc getTclModuleList {} {
    if {[catch {package require fileutil} errmsg]!=0} {
        return -code error $errmsg
    }

    set tmFileList [list]
    set tmpaths [::tcl::tm::path list]
    foreach tmpath $tmpaths {
        if {[file exists $tmpath] && [file isdirectory $tmpath]} {
            foreach file [fileutil::find $tmpath {string match -nocase *.tm}] {
                lappend tmFileList $file
            }
        }
    }

    return $tmFileList
}

proc base64url_encode {string} {
    tailcall string map {+ - / _ = {}} [binary encode base64 $string]
}

proc base64url_decode {string} {
    tailcall binary decode base64 [string map {- + _ /} $string]
}
