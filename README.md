# DaniloTools

It is jus for fun to create Danilo' Tcl Tools Package.

## funcall

It is a wrapper for Tcl/TK [apply](http://www.tcl.tk/man/tcl/TclCmd/apply.htm) command and normal procedure.

    package require DaniloTools

    proc add {a b} {
        return [expr $a + $b]
    }

    set myadd add

    set add2 {{a b} {
        return [expr $a + $b]
    }}

    funcall add 10 20
    funcall $myadd 10 20
    funcall $add2 10 20
    funcall tcl::mathop::+ 10 20
    funcall expr 10 + 20

## is_threaded

It is a simple method to check support thread or not.


## PipeCommand

It is a [TclOO class](http://www.tcl.tk/man/tcl/TclCmd/class.htm),
for handle input and output for open command pipeline.

    package require DaniloTools

    set client [PipeCommand new cat]
    $client writeInput "Use the force, Luke."
    set result [$client readOutput]
    $client destroy

    puts "Result: $result"


## uname

It is using `uname` command to get system information on
Linux or UNIX-like platform.

Have below functions:  
::uname::getKernelName  
::uname::getNodeName  
::uname::getRelease  
::uname::getVersion  
::uname::getMachine  
::uname::getOperatingSyste  


## untargzipfile

Handle a .tar.gz file (decompress).

Notice: Sorry, it is not always work.
Untar looks like have limits and not supported type.

## targzipfile

Compress to a .tar.gz file

## getTclModuleList

Get Tcl module list from `::tcl::tm::path` list paths.

## base64url_encode

Encode base64url

## base64url_decode

Decode base64url

