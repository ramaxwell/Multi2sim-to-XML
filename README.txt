# This script is adapted from a script I saw in the multi2sim-4.0 release and
# I began to expand it to support heterogeneous capabilities in M2S and McPAT.
# (Note: after a little searching I believe the original author and branch is here:
# https://github.com/Peilong/multi2sim-4.0-hc.git
# path --> multi2sim-4.0-hc/McPAT08release/m2s2xml.sh 
#
# M2S reports core and thread level information and a lot of it. But to represent
# hetero cores in McPAT, we just have to set the homogeneous_cores flag to zero.
# Then McPat will expect seperate XML objects for system.core0,system.core1, etc...
# It is the same for uncore objects (homogeneous_L2s,homogeneous_L3s,...)
# 
# This script attempts to detect number of cores, number of il1 (i-cache), 
# number of l1 (d-cache), l2 cache modules and uses the info from 
# X86 & MEM reports to create an XML file for use with McPat.
#
# This is the first version and it's pretty messy. It has only been tested on
# a 2 core, 2 thread system config setup (penryn-like core), running single-
# threaded spec06 benchmarks. 
# 
# Many of the architectural parameters could not be connected together for
# instance L1 and L2 directories, machine bits, opcode_width, machine_type, etc...
# aren't configured/reported in M2S. These must be configured by hand based on the
# architecture you are trying to simulate in McPAT.
#
# Some parameters are reported and configurable 
# but don't match the verbage such as IQ.reads in M2S and inst_window_reads in McPat
# And some match closely (in name) as in DecodeWidth in M2S and decode_width in McPat
# The file README.mapping shows the McPAT parameters and stats that are mapped to M2S
# 
#
# In some places I wrote a FIXME to remind myself that I was applying a band-aid
# to a problem or that I really don't understand the nomenclature. For instance when 
# I set cdb_alu_accesses = ialu_access which is just Issue.Integer in M2S...This is a 
# bit of a stretch and possibly flatout inaccurate. I just don't know because I am not
# familiar with inferring common-data-bus statistics in M2S.
# 
#
# Notes and Assumptions:
#	1.) M2S (version 4.2) has produced x86 and MEM reports
#	2.) Modules in MEM report and by extention M2S MEM Config file,
#		 must be labeled by naming convention: "[ module-cpuType-memLevel-number ]" 
#		 --> for instance the first L2 cache module is [ mod-x86-l2-0 ]
#		 	 and the second L2 cache module is [ mod-x86-l2-1 ]
#		 	 and so-on
#		 --> Also iCache is [ mod-x86-il1-0 ]   (il1-1,il1-2,...)
#		 	 and dCache is [ mod-x86-l1-0 ] 	(l1-1,l1-2,...)
#	3.) Info gathered from X86 report only uses core-level stats, not thread-level
#		 --> For instance: M2S reports core-level stats as [ c0 ] (c1,c2,c3,...)
#		 	 and thread-level stats as [ c0t0 ] (c0t1,c0t2,...c1t0,c1t1,...)
#		 --> Getting thread-level stats has been left to future authors
