#!/bin/bash
#
# Convenience script to help produce the code coverage report for
# testsuite. Should be run from the same dir where haskell-mpi.cabal
# is located and after "cabal install" or "cabal build" has been run

rm -f *.tix
[ -f coverage.dirs ] && (
    readarray -t dirs < coverage.dirs
    for dir in "${dirs[@]}" ; do
        [ -d $d ] && rm -rf $dir
    done
    rm coverage.dirs
)
mpirun -np 5 bash -c 'mkdir $$ && echo $$ >> coverage.dirs && cd $$ && haskell-mpi-testsuite +RTS -ls' 2>receivers.log | tee sender.log

# Combine logs from profiler and eventlog
readarray -t dirs < coverage.dirs
hpc combine --output=rank01.tix ${dirs[0]}/rank*.tix ${dirs[1]}/rank*.tix
hpc combine --output=rank23.tix ${dirs[2]}/rank*.tix ${dirs[3]}/rank*.tix
hpc combine --output=rank0123.tix rank01.tix rank23.tix
hpc combine --output=haskell-mpi-testsuite.tix rank0123.tix ${dirs[4]}/rank*.tix
hpc markup --destdir=./html haskell-mpi-testsuite.tix
hpc report haskell-mpi-testsuite.tix
