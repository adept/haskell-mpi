#
# This script converts output from ghc-events into input suitable for "splot" (cabal install splot)
#
# Assumptions: eventlog is obtained from MPI program built with haskell-mpi with profiling turned on
# (so that Internal.chs would emit MPI tracing messages in the eventlog)
#
# Example of the relevant messages in the eventlog dump
# 1134483000: cap 0: 0 MPI-START barrier
# 1137761000: cap 0: 0 MPI-FINISH barrier
# 1137780000: cap 0: 0 MPI-START send
# 1137802000: cap 0: 0 MPI-FINISH send
# 1138095000: cap 0: 1 MPI-START barrier
# 1141345000: cap 0: 1 MPI-FINISH barrier
# 1141353000: cap 0: 1 MPI-START send
# 1141357000: cap 0: 1 MPI-FINISH send
# 1141619000: cap 0: 0 MPI-START barrier
# 1142978000: cap 0: 0 MPI-FINISH barrier
# , where first field is timestamp, fourth (integer) is the MPI rank of the process.
#
# This script could be fed multiple eventlogs at once like this:
# 
#   for f in [0-9]*/*.eventlog ; do ghc-events show $f ; done \
#     | awk -f eventlog2splot.awk \
#     | splot -tf "%^-9s" -sort name -w 1200 -h 800 -bh 20 -o splot.png
#
# Note that since eventlog time is relative to the program start time, this code assumes
# that there is a "barrier" invocation done first thing after MPI initialization. This
# script attempts to synchronize the clock marks in all files by the end of the first
# "barrier" call.
#
#
{ gsub(":","",$1); rank="rank"$4; time=(rank in sync)?($1-sync[rank]):($1) }
/MPI-START barrier/ {if (rank in sync) {print time " >" rank " blue";}next;}
/MPI-START i?[rs]?send/ {print time " >" rank " green";next;}
/MPI-START i?recv/ {print time " >" rank " green";next;}
/MPI-START bcast/ {print time " >" rank " red";next;}
/MPI-START scatter/ {print time " >" rank " brown";next;}
/MPI-START gather/ {print time " >" rank " black";next;}
/MPI-START all/ {print time " >" rank " magenta";next;}
/MPI-START reduce/ {print time " >" rank " yellow";next;}
/MPI-START/ {print time " >" rank " cyan"}
/MPI-FINISH barrier/ {if (!(rank in sync)) {sync[rank]=time; next;};}
/MPI-FINISH/ {print time " <" rank}
