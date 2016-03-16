#!/bin/bash
#
# PLEASE look at the README!!
#
#
#
# Usage: >> ./myM2S2XML.sh <cpu_report> <mem_report> <output.xml>
#
# $1=CPU Report
# $2=MEM Report
# $3=Output Filename = McPAT XML File
#
#

#-------------------
# Special Modules
#-------------------

# Count the number of modules l1-0,l1-1,etc
# $1 : search string
# $2 : file to grep
count_modules()
{
    
    for i in $(seq 0 20)
    do
      
       if grep -q -m 1 $1-$i $2
       then
           count=$((count + 1)) 
       fi
    done
}


# Count number of cache levels
# $1 : search string
# $2 : file to grep
count_levels()
{
    for i in $(seq 1 5)
    do

        if grep -q -m 1 "$1$i" $2
        then
           count=$((count + 1)) 
        fi
    done
}

reset_stats()
{
    sets=0
    assoc=0
    bSize=0
    lat=0    
    size=0
}

#----------------------
# Input and output
#----------------------
#input file1 (M2s CPU Report output)
IN_M2S_CPU=$1

#input file2 (M2s MEM Report output)
IN_M2S_MEM=$2

#output file (new mcpat xml file)
OUT_XML=$3


#----------------------------------------------------
# Begin XML output
#----------------------------------------------------

#########
#Doctype 
env printf "<?xml version=\"1.0\" ?>\n" > $OUT_XML
#####
#Root
env printf "<component id=\"root\" name=\"root\">\n" >> $OUT_XML
########
#System
env printf "    <component id=\"system\" name=\"system\">\n" >> $OUT_XML
#########
#General
#########
	cores=$(grep  -m 1 "Cores"   $IN_M2S_CPU | sed "s;Cores = \(.*\);\1;")
	env printf "        <param name=\"number_of_cores\" value=\"%s\"/><!-- * -->\n" $cores >> $OUT_XML
	env printf "        <param name=\"number_of_L1Directories\" value=\"0\"/>\n" >> $OUT_XML	
	#no Directory stats
	env printf "        <param name=\"number_of_L2Directories\" value=\"0\"/>\n" >> $OUT_XML	
	#output from m2s (yet)

	count=0
	count_modules "mod-x86-l2" $IN_M2S_MEM
	numL2s=$count

	env printf "        <param name=\"number_of_L2s\" value=\"%i\"/><!-- * -->\n" $numL2s >> $OUT_XML

	#don't Know (Private_L2)	
	env printf "        <param name=\"Private_L2\" value=\"0\"/>\n" >> $OUT_XML

	echo "***************************************"
	echo "Multi2Sim --> McPAT XML"
	echo "***************************************"
	echo "Cores: $cores"
	echo "# L2s: $numL2s"

	count=0
	count_modules "mod-x86-l3" $IN_M2S_MEM
	numL3s=$count

	env printf "        <param name=\"number_of_L3s\" value=\"%i\"/><!-- * -->\n" $count >> $OUT_XML
	echo "# L3s: $numL3s"

	#FIXME(NET REPORT)	
	env printf "        <param name=\"number_of_NoCs\" value=\"2\"/>\n" >> $OUT_XML
	#
	#need to change for hetero cores
	# For our purposes hetero cores means the statistics reported by the 
	#	performance simulator are different in multicore situation
	#	(I.e., core0(Dispatch.Integer) != core1(Dispatch.Integer)  )
	# hetero:0 , homo:1
	
	#TODO These params need to be alterred by hand
	env printf "        <param name=\"homogeneous_cores\" value=\"0\"/>\n" >> $OUT_XML
	env printf "        <param name=\"homogeneous_L2s\" value=\"0\"/>\n" >> $OUT_XML
	env printf "        <param name=\"homogeneous_L1Directorys\" value=\"1\"/>\n" >> $OUT_XML
	env printf "        <param name=\"homogeneous_L2Directorys\" value=\"1\"/>\n" >> $OUT_XML
	env printf "        <param name=\"homogeneous_L3s\" value=\"1\"/>\n" >> $OUT_XML
	env printf "        <param name=\"homogeneous_ccs\" value=\"1\"/>\n" >> $OUT_XML
	env printf "        <param name=\"homogeneous_NoCs\" value=\"0\"/>\n" >> $OUT_XML
	env printf "        <param name=\"core_tech_node\" value=\"45\"/>\n" >> $OUT_XML

	m2s_data=$(grep  -m 1 "Frequency"   $IN_M2S_CPU | sed "s;Frequency = \(.*\);\1;")
	env printf "        <param name=\"target_core_clockrate\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
	#TODO if temperature changes are simulated
	env printf "        <param name=\"temperature\" value=\"300\"/>\n" >> $OUT_XML	#About Room Temp

	count=0
	count_levels "mod-x86-l" $IN_M2S_MEM
	echo "# Cache Levels: $count"
	echo "-----------------------------------"
	env printf "        <param name=\"number_cache_levels\" value=\"%i\"/><!-- * -->\n" $count >> $OUT_XML
	#TODO MUST input by hand (just once)
	env printf "        <param name=\"interconnect_projection_type\" value=\"0\"/>\n" >> $OUT_XML
	env printf "        <param name=\"device_type\" value=\"0\"/>\n" >> $OUT_XML
	#<!--0: HP(High Performance Type); 1: LSTP(Low standby power) 2: LOP (Low Operating Power)  -->
	env printf "        <param name=\"longer_channel_device\" value=\"1\"/>\n" >> $OUT_XML
	#<!-- 0 no use; 1 use when approperiate -->
	env printf "        <param name=\"power_gating\" value=\"1\"/>\n" >> $OUT_XML			
	#from mcpat xml: 1=Enabled
	env printf "        <param name=\"machine_bits\" value=\"64\"/>\n" >> $OUT_XML			
	#from mcpat sample xml
	env printf "        <param name=\"virtual_address_width\" value=\"64\"/>\n" >> $OUT_XML			
	#FROM mcpat sample xml
	env printf "        <param name=\"physical_address_width\" value=\"52\"/>\n" >> $OUT_XML		

	#FIXME pagesize issues
	#m2s_data=$(grep  -m 1 "PageSize"   $IN_M2S_CPU | sed "s;PageSize = \(.*\);\1;")
	#env printf "        <param name=\"virtual_memory_page_size\" value=\"%s\"/>\n" $m2s_data >> $OUT_XML
	env printf "        <param name=\"virtual_memory_page_size\" value=\"4096\"/>\n" >> $OUT_XML

	m2s_data=$(grep  -m 1 "Cycles"   $IN_M2S_CPU | sed "s;Cycles = \(.*\);\1;")
	env printf "        <stat name=\"total_cycles\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML

	#FIXME Idle cycles can change with multiple chips
	# core specific idle cycles reported at core0,core1,etc...
	env printf "        <stat name=\"idle_cycles\" value=\"0\"/>\n" >> $OUT_XML

	#For Single thread benchmark, all cycles are busy cycles at chip level
	#m2s_data=$(grep  -m 1 "Cycles"   $IN_M2S_CPU | sed "s;Cycles = \(.*\);\1;")
	env printf "        <stat name=\"busy_cycles\"  value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
	################
	#Cores				Assumes each core is explicitly defined from M2S
	################    
		for j in $(seq 0 $(( cores - 1 )) )									#Possible Cores*Threads
		do
		    env printf "        <component id=\"system.core$j\" name=\"core\">\n" >> $OUT_XML
			# doesn't account for multiple core clock domains
			core_freq=$(grep  -m 1 "Frequency"   $IN_M2S_CPU | sed "s;Frequency = \(.*\);\1;")
			printf "Core Frequency:  %s\n" $core_freq		
 			
		    env printf "            <param name=\"clock_rate\" value=\"%s\"/><!-- * -->\n" $core_freq >> $OUT_XML
			#TODO
			#These next 7 lines require manual input (not included in M2S output file)
			#
			env printf "			<param name=\"vdd\" value=\"0\"/>\n" >> $OUT_XML
		    #<!-- for cores with unknow timing, set to 0 to force off the opt flag -->
		    env printf "            <param name=\"opt_local\" value=\"1\"/>\n" >> $OUT_XML
		    env printf "            <param name=\"instruction_length\" value=\"32\"/>\n" >> $OUT_XML
		    env printf "            <param name=\"opcode_width\" value=\"16\"/>\n" >> $OUT_XML
		    env printf "            <param name=\"x86\" value=\"1\"/>\n" >> $OUT_XML
		    env printf "            <param name=\"micro_opcode_width\" value=\"8\"/>\n" >> $OUT_XML
		    env printf "            <param name=\"machine_type\" value=\"0\"/>\n" >> $OUT_XML
					#<!-- (More like Core type)       inorder/OoO; 1 inorder; 0 OOO-->
		
		    numThds=$(grep  -m 1 "Threads"   $IN_M2S_CPU | sed "s;Threads = \(.*\);\1;")			
		    env printf "            <param name=\"number_hardware_threads\" value=\"%s\"/><!-- * -->\n" $numThds >> $OUT_XML
			#TODO Fetch width is not included in M2S x86 report
		    env printf "            <param name=\"fetch_width\" value=\"4\"/>\n" >> $OUT_XML
		    #<!-- same number IF ports as number of threads -->
		    env printf "            <param name=\"number_instruction_fetch_ports\" value=\"%s\"/><!-- ^ -->\n" $numThds >> $OUT_XML	
		    m2s_data=$(grep  -m 1 "DecodeWidth"   $IN_M2S_CPU | sed "s;DecodeWidth = \(.*\);\1;")
		    env printf "            <param name=\"decode_width\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep  -m 1 "IssueWidth"   $IN_M2S_CPU | sed "s;IssueWidth = \(.*\);\1;")
		    env printf "            <param name=\"issue_width\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
			#<!-- Peak_issue-Width (From sample mcpat xml file)    -->
		    env printf "            <param name=\"peak_issue_width\" value=\"6\"/>\n" >> $OUT_XML

		    m2s_data=$(grep  -m 1 "CommitWidth"   $IN_M2S_CPU | sed "s;CommitWidth = \(.*\);\1;")
		    env printf "            <param name=\"commit_width\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
			#<!--  FP Issue Width (from sample mcpat Penryn.xml file) -->
		   # m2s_data=$(grep  -m 1 "FloatSimple.Count"   $IN_M2S_CPU | sed "s;FloatSimple.Count = \(.*\);\1;")
		    env printf "            <param name=\"fp_issue_width\" value=\"2\"/>\n" >> $OUT_XML
			#<!--  Prediction Width (from sample mcpat Penryn.xml file) -->
		    env printf "            <param name=\"prediction_width\" value=\"1\"/>\n" >> $OUT_XML
			#<!--from mcpat sample Penryn.xml file -->		    
			env printf "            <param name=\"pipelines_per_core\" value=\"1,1\"/>\n" >> $OUT_XML
		    #<!--integer_pipeline and floating_pipelines, if the floating_pipelines is 0, then the pipeline is shared-->

			#<!--from mcpat sample Penryn.xml file -->
		    env printf "            <param name=\"pipeline_depth\" value=\"14,14\"/>\n" >> $OUT_XML

		    m2s_data=$(grep -m 1 "IntAdd.Count" $IN_M2S_CPU | sed "s;IntAdd.Count = \(.*\);\1;")
		    env printf "            <param name=\"ALU_per_core\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep  -m 1 "IntMult.Count"   $IN_M2S_CPU | sed "s;IntMult.Count = \(.*\);\1;")
		    env printf "            <param name=\"MUL_per_core\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    #m2s_data=$(grep  -m 1 "FloatSimple.Count"   $IN_M2S_CPU | sed "s;FloatSimple.Count = \(.*\);\1;")
			# FIXME!! Unsure about bringing this STAT together
		    env printf "            <param name=\"FPU_per_core\" value=\"2\"/>\n" >> $OUT_XML
		    m2s_data=$(grep  -m 1 "FetchQueueSize"   $IN_M2S_CPU | sed "s;FetchQueueSize = \(.*\);\1;")
		    env printf "            <param name=\"instruction_buffer_size\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep  -m 1 "UopQueueSize"   $IN_M2S_CPU | sed "s;UopQueueSize = \(.*\);\1;")
		    env printf "            <param name=\"decoded_stream_buffer_size\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    #<!-- 0 PHYREG based, 1 RSBASED-->
  		  	#<!-- McPAT support 2 types of OoO cores, RS based and physical reg based-->
			#Reservation station scheme based on Penryn and mcpat documentation
		    env printf "            <param name=\"instruction_window_scheme\" value=\"1\"/>\n" >> $OUT_XML

		    m2s_data=$(grep  -m 1 "IqSize"   $IN_M2S_CPU | sed "s;IqSize = \(.*\);\1;")
		    env printf "            <param name=\"instruction_window_size\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML

		    #FP same as instruction window size
		    env printf "            <param name=\"fp_instruction_window_size\" value=\"%s\"/>\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep  -m 1 "RobSize"   $IN_M2S_CPU | sed "s;RobSize = \(.*\);\1;")
		    env printf "            <param name=\"ROB_size\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML


		    #<!-- X86-64 has 16GPR -->	
		    #instruction register file
		    m2s_data=$(grep  -m 1 "RfIntSize"   $IN_M2S_CPU | sed "s;RfIntSize = \(.*\);\1;")
		    env printf "            <param name=\"archi_Regs_IRF_size\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    #<!-- MMX + XMM -->
		    #<!--  if OoO processor, phy_reg number is needed for renaming logic, 
		    #renaming logic is for both integer and floating point insts.  -->
		    #Floating point register file
		    m2s_data=$(grep  -m 1 "RfFpSize"   $IN_M2S_CPU | sed "s;RfFpSize = \(.*\);\1;")
		    env printf "            <param name=\"archi_Regs_FRF_size\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    #m2s_data=$(grep  -m 1 "RfIntSize"   $IN_M2S_CPU | sed "s;RfIntSize = \(.*\);\1;")
		    env printf "            <param name=\"phy_Regs_IRF_size\" value=\"256\"/>\n" >> $OUT_XML
		    #m2s_data=$(grep  -m 1 "RfFpSize"   $IN_M2S_CPU | sed "s;RfFpSize = \(.*\);\1;")
		    env printf "            <param name=\"phy_Regs_FRF_size\" value=\"256\"/>\n" >> $OUT_XML

		    #<!-- rename logic -->
			#0-RAM based, 1-CAM based
		    env printf "            <param name=\"rename_scheme\" value=\"0\"/>\n" >> $OUT_XML
		    env printf "            <param name=\"register_windows_size\" value=\"0\"/>\n" >> $OUT_XML
		    #<!-- how many windows in the windowed register file, sun processors;
		    #no register windowing is used when this number is 0 -->
		    #<!-- In OoO cores, loads and stores can be issued whether inorder(Pentium Pro) or (OoO)out-of-order(Alpha),
		    #They will always try to execute out-of-order though. -->
		    env printf "            <param name=\"LSU_order\" value=\"inorder\"/>\n" >> $OUT_XML

			
			#FIXME !!!!LD/ST Buffer sizes are from documentation but M2S doesn't support seperate Ld/ST buffers
		    #m2s_data=$(grep  -m 1 "LsqSize"   $IN_M2S_CPU | sed "s;LsqSize = \(.*\);\1;")
		    env printf "            <param name=\"store_buffer_size\" value=\"96\"/>\n" >> $OUT_XML
		    #<!-- By default, in-order cores do not have load buffers -->
		    env printf "            <param name=\"load_buffer_size\" value=\"48\"/>\n" >> $OUT_XML
		    #<!-- number of ports refer to sustainable concurrent memory accesses --> 
		    env printf "            <param name=\"memory_ports\" value=\"2\"/>\n" >> $OUT_XML
		    m2s_data=$(grep  -m 1 "RAS.Size"   $IN_M2S_CPU | sed "s;RAS.Size = \(.*\);\1;")
    		env printf "            <param name=\"RAS_size\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
    		m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "Dispatch.Total" | sed "s;Dispatch.Total = \(.*\);\1;")
		    env printf "            <stat name=\"total_instructions\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "Dispatch.Integer" | sed "s;Dispatch.Integer = \(.*\);\1;")
		    env printf "            <stat name=\"int_instructions\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "Dispatch.FloatingPoint" | sed "s;Dispatch.FloatingPoint = \(.*\);\1;")
		    env printf "            <stat name=\"fp_instructions\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML

		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "Dispatch.Ctrl" | sed "s;Dispatch.Ctrl = \(.*\);\1;")
		    env printf "            <stat name=\"branch_instructions\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "Commit.Mispred" | sed "s;Commit.Mispred = \(.*\);\1;")
		    env printf "            <stat name=\"branch_mispredictions\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "Dispatch.Uop.load" | sed "s;Dispatch.Uop.load = \(.*\);\1;")
		    env printf "            <stat name=\"load_instructions\" value=\"%s\"/><!-- * -->\n" $m2s_data>> $OUT_XML
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "Dispatch.Uop.store" | sed "s;Dispatch.Uop.store = \(.*\);\1;")
		    env printf "            <stat name=\"store_instructions\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "Commit.Total" | sed "s;Commit.Total = \(.*\);\1;")
		    env printf "            <stat name=\"committed_instructions\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "Commit.Integer" | sed "s;Commit.Integer = \(.*\);\1;")
		    env printf "            <stat name=\"committed_int_instructions\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "Commit.FloatingPoint" | sed "s;Commit.FloatingPoint = \(.*\);\1;")
		    env printf "            <stat name=\"committed_fp_instructions\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    #m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "Commit.DutyCycle" | sed "s;Commit.DutyCycle = \(.*\);\1;")
			#FIXME !!!Duty cycle ISSUES - unclear here!!!
		    env printf "            <stat name=\"pipeline_duty_cycle\" value=\"1\"/>\n" >> $OUT_XML

			#FIXME -- This is incomplete, but was intended to show busy 
			#         and idle cycle counts for different threads
			#		  
			m2s_data=$(grep  -m 1 "Cycles"   $IN_M2S_CPU | sed "s;Cycles = \(.*\);\1;")
			env printf "            <stat name=\"total_cycles\" value=\"%s\"/>\n" $m2s_data >> $OUT_XML

			if [ "$numThds" -le 1 ] && [ "$j" -eq 0 ]; then
					
			    env printf "            <stat name=\"idle_cycles\" value=\"0\"/>\n" >> $OUT_XML
			    env printf "            <stat name=\"busy_cycles\"  value=\"%s\"/>\n" $m2s_data >> $OUT_XML
				
			else
			
			    env printf "            <stat name=\"idle_cycles\" value=\"%s\"/>\n" $m2s_data >> $OUT_XML
			    env printf "            <stat name=\"busy_cycles\"  value=\"0\"/>\n" >> $OUT_XML
									#IDLE Cycles
			fi

		    m2s_data=$(grep -A 340 "c$j" $IN_M2S_CPU | grep  -m 1 "ROB.Reads" | sed "s;ROB.Reads = \(.*\);\1;")
		    env printf "            <stat name=\"ROB_reads\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 340 "c$j" $IN_M2S_CPU | grep  -m 1 "ROB.Writes" | sed "s;ROB.Writes = \(.*\);\1;")
		    env printf "            <stat name=\"ROB_writes\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "RAT.IntReads" | sed "s;RAT.IntReads = \(.*\);\1;")
		    env printf "            <stat name=\"rename_reads\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "RAT.IntWrites" | sed "s;RAT.IntWrites = \(.*\);\1;")
		    env printf "            <stat name=\"rename_writes\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "RAT.FpReads" | sed "s;RAT.FpReads = \(.*\);\1;")
		    env printf "            <stat name=\"fp_rename_reads\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "RAT.FpWrites" | sed "s;RAT.FpWrites = \(.*\);\1;")
		    env printf "            <stat name=\"fp_rename_writes\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
#
#	Int instruction window reads/etc
#
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "IQ.Reads" | sed "s;IQ.Reads = \(.*\);\1;")
		    env printf "            <stat name=\"inst_window_reads\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
    		m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "IQ.Writes" | sed "s;IQ.Writes = \(.*\);\1;")
		    env printf "            <stat name=\"inst_window_writes\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "IQ.WakeupAccesses" | sed "s;IQ.WakeupAccesses = \(.*\);\1;")
		    env printf "            <stat name=\"inst_window_wakeup_accesses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
#
#	FP instruction window reads/etc
#	!FIXME
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "Issue.FloatingPoint" | sed "s;Issue.FloatingPoint = \(.*\);\1;")
		    env printf "            <stat name=\"fp_inst_window_reads\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "RF_Fp.Writes" | sed "s;RF_Fp.Writes = \(.*\);\1;")
		    env printf "            <stat name=\"fp_inst_window_writes\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "Issue.FloatingPoint" | sed "s;Issue.FloatingPoint = \(.*\);\1;")
		    env printf "            <stat name=\"fp_inst_window_wakeup_accesses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "RF_Int.Reads" | sed "s;RF_Int.Reads = \(.*\);\1;")
		    env printf "            <stat name=\"int_regfile_reads\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "RF_Fp.Reads" | sed "s;RF_Fp.Reads = \(.*\);\1;")
		    env printf "            <stat name=\"float_regfile_reads\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "RF_Int.Writes" | sed "s;RF_Int.Writes = \(.*\);\1;")
		    env printf "            <stat name=\"int_regfile_writes\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "RF_Fp.Writes" | sed "s;RF_Fp.Writes = \(.*\);\1;")
		    env printf "            <stat name=\"float_regfile_writes\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "Dispatch.Uop.call" | sed "s;Dispatch.Uop.call = \(.*\);\1;")
		    env printf "            <stat name=\"function_calls\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "Dispatch.WndSwitch" | sed "s;Dispatch.WndSwitch = \(.*\);\1;")
		    env printf "            <stat name=\"context_switches\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML

		    ialu_access=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "Issue.Integer" | sed "s;Issue.Integer = \(.*\);\1;")
		    env printf "            <stat name=\"ialu_accesses\" value=\"%s\"/><!-- * -->\n" $ialu_access >> $OUT_XML
		    fpu_access=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "Issue.FloatingPoint" | sed "s;Issue.FloatingPoint = \(.*\);\1;")
		    env printf "            <stat name=\"fpu_accesses\" value=\"%s\"/><!-- * -->\n" $fpu_access >> $OUT_XML
			
			# McPAT doesn't differentiate multiplies and divides so I combined them below
			#
			div_access=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "Issue.Uop.div" | sed "s;Issue.Uop.div = \(.*\);\1;")
			#echo "Divider accesses: $div_access" 
		    mult_access=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "Issue.Uop.mult" | sed "s;Issue.Uop.mult = \(.*\);\1;")
			#echo "Multiplier accesses: $mult_access" 
			mul_div=$((div_access + mult_access))
			#echo "MUL_DIV: $mul_div" 
		    env printf "            <stat name=\"mul_accesses\" value=\"%s\"/><!-- * -->\n" $mul_div >> $OUT_XML

		    env printf "            <stat name=\"cdb_alu_accesses\" value=\"%s\"/><!-- * -->\n" $ialu_access >> $OUT_XML

		    env printf "            <stat name=\"cdb_mul_accesses\" value=\"%s\"/><!-- * -->\n" $mul_div >> $OUT_XML

		    env printf "            <stat name=\"cdb_fpu_accesses\" value=\"%s\"/><!-- * -->\n" $fpu_access >> $OUT_XML

			#FIXME -- I didn't change any of the duty cycle info from the penryn.xml file
		    env printf "            <stat name=\"IFU_duty_cycle\" value=\"0.25\"/>\n" >> $OUT_XML
		    env printf "            <stat name=\"LSU_duty_cycle\" value=\"0.25\"/>\n" >> $OUT_XML
		    env printf "            <stat name=\"MemManU_I_duty_cycle\" value=\"0.25\"/>\n" >> $OUT_XML
		    env printf "            <stat name=\"MemManU_D_duty_cycle\" value=\"0.25\"/>\n" >> $OUT_XML
		    env printf "            <stat name=\"ALU_duty_cycle\" value=\"1\"/>\n" >> $OUT_XML
		    env printf "            <stat name=\"MUL_duty_cycle\" value=\"0.3\"/>\n" >> $OUT_XML
		    env printf "            <stat name=\"FPU_duty_cycle\" value=\"0.3\"/>\n" >> $OUT_XML
		    env printf "            <stat name=\"ALU_cdb_duty_cycle\" value=\"1\"/>\n" >> $OUT_XML
		    env printf "            <stat name=\"MUL_cdb_duty_cycle\" value=\"0.3\"/>\n" >> $OUT_XML
		    env printf "            <stat name=\"FPU_cdb_duty_cycle\" value=\"0.3\"/>\n" >> $OUT_XML

			#-------------------------
    		#Core-X Branch Predictor
			#-------------------------
    		#M2S default 2-level predictor
			# !!FIXME -- predictor architecture is not imported from multi2sim
		    env printf "            <param name=\"number_of_BPT\" value=\"2\"/>\n" >> $OUT_XML	
		    env printf "            <component id=\"system.core$j.predictor\" name=\"PBT\">\n" >> $OUT_XML
		    #width in bits of the two, first level tables <table1 width, table2 width>
		    env printf "                <param name=\"local_predictor_size\" value=\"10,3\"/>\n" >> $OUT_XML
		    env printf "                <param name=\"local_predictor_entries\" value=\"1024\"/>\n" >> $OUT_XML
		    env printf "                <param name=\"global_predictor_entries\" value=\"4096\"/>\n" >> $OUT_XML
		    env printf "                <param name=\"global_predictor_bits\" value=\"2\"/>\n" >> $OUT_XML
		    env printf "                <param name=\"chooser_predictor_entries\" value=\"4096\"/>\n" >> $OUT_XML
			env printf "                <param name=\"chooser_predictor_bits\" value=\"2\"/>\n" >> $OUT_XML
		    m2s_data=$(grep -A 300 "c$j" $IN_M2S_CPU | grep  -m 1 "Issue.Ctrl" | sed "s;Issue.Ctrl = \(.*\);\1;")
			env printf "				<stat name=\"predictor_accesses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    env printf "            </component>\n" >> $OUT_XML

			#-------------------------------------------------
		    #Core X Instr. Translation Lookaside Buffer (ITLB)
			#-------------------------------------------------
		    #not implemented in M2S
			#!!FIXME - approximated by using i-cache accesses/misses/evictions

		    env printf "            <component id=\"system.core$j.itlb\" name=\"itlb\">\n" >> $OUT_XML
   			env printf "                <param name=\"number_entries\" value=\"128\"/>\n" >> $OUT_XML
    		
		    m2s_data=$(grep -A 15 "mod-x86-il1-$j" $IN_M2S_MEM | grep "Accesses" | sed "s;Accesses = \(.*\);\1;")
			env printf "                <stat name=\"total_accesses\" value=\"%s\"/><!-- ^ -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 15 "mod-x86-il1-$j" $IN_M2S_MEM | grep "Misses" | sed "s;Misses = \(.*\);\1;")
    		env printf "                <stat name=\"total_misses\" value=\"%s\"/><!-- ^ -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 15 "mod-x86-il1-$j" $IN_M2S_MEM | grep "Evictions" | sed "s;Evictions = \(.*\);\1;")
    		env printf "                <stat name=\"conflicts\" value=\"%s\"/><!-- ^ -->\n" $m2s_data >> $OUT_XML
    		env printf "            </component>\n" >> $OUT_XML

			#-------------------------------------
		    #Core X Instruction Cache : multiple caches
			#-------------------------------------

		    env printf "            <component id=\"system.core$j.icache\" name=\"icache\">\n" >> $OUT_XML
		    #(HETERO) whichever core is accessed: [ mod-cpu-l1-i0 ], [ mod-cpu-l1-i1 ]  

		    # 52 is #lines after initial grep to grep again
		    sets=$(grep -A 52 "mod-x86-il1-$j" $IN_M2S_MEM | grep "Sets" | sed "s;Sets = \(.*\);\1;")
		    assoc=$(grep -A 52 "mod-x86-il1-$j" $IN_M2S_MEM | grep "Assoc" | sed "s;Assoc = \(.*\);\1;")
		    bSize=$(grep -A 52 "mod-x86-il1-$j" $IN_M2S_MEM | grep "BlockSize" | sed "s;BlockSize = \(.*\);\1;")
		    lat=$(grep -A 52 "mod-x86-il1-$j" $IN_M2S_MEM | grep "Latency" | sed "s;Latency = \(.*\);\1;")    
		    size=$(( sets * assoc * bSize ))

		    #still need params: bank, throughput wrt core clock, output width
		    env printf "                <param name=\"icache_config\" value=\"%i,%s,%s,1,4,%s,32,0\"/>\n" $size $bSize $assoc $lat  >> $OUT_XML
		    echo "L1-ICache-$j"
			echo "-------------"
			echo "Size: $size"
			echo "# Sets: $sets"
			echo "Assoc: $assoc"
			echo "Blk Size: $bSize"

		    #<!-- the parameters are: capacity,
			#						 block_width, 
			#						 associativity, 
			#						 bank, 
			#						 throughput w.r.t. core clock, 
			#						 latency w.r.t. core clock,
			#						 output_width, 
			#						 cache policy,  
			#						 -->
		    #<!-- cache_policy : 
			#			0 no write or write-though with non-write allocate
			#			1 write-back with write-allocate 
			#			-->
		    #Default MSHR: 16, fill_buffer:? , prefetch (PrefetcherGHBSize): 256, WB buffer:?
		    env printf "                <param name=\"buffer_sizes\" value=\"16, 16, 16,0\"/>\n" >> $OUT_XML

	#STATS#
		    m2s_data=$(grep -A 52 "mod-x86-il1-$j" $IN_M2S_MEM | grep -m 1 "Accesses" | sed "s;Accesses = \(.*\);\1;")
		    env printf "                <stat name=\"total_accesses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 52 "mod-x86-il1-$j" $IN_M2S_MEM | grep -m 1 "Hits" | sed "s;Hits = \(.*\);\1;")
		    env printf "                <stat name=\"total_hits\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 52 "mod-x86-il1-$j" $IN_M2S_MEM | grep -m 1 "Misses" | sed "s;Misses = \(.*\);\1;")
		    env printf "                <stat name=\"total_misses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML

			
		    #<!-- cache controller buffer sizes: miss_buffer_size(MSHR),fill_buffer_size,prefetch_buffer_size,wb_buffer_size-->
		    m2s_data=$(grep -A 52 "mod-x86-il1-$j" $IN_M2S_MEM | grep -m 1 "Reads" | sed "s;Reads = \(.*\);\1;")
		    env printf "                <stat name=\"read_accesses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 52 "mod-x86-il1-$j" $IN_M2S_MEM | grep -m 1 "ReadMisses" | sed "s;ReadMisses = \(.*\);\1;")
		    env printf "                <stat name=\"read_misses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 52 "mod-x86-il1-$j" $IN_M2S_MEM | grep -m 1 "ReadHits" | sed "s;ReadHits = \(.*\);\1;")
		    env printf "                <stat name=\"read_hits\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML

		    #Not sure if this is a good correlation (NoRetryReadMisses == conflicts)?
		    m2s_data=$(grep -A 52 "mod-x86-il1-$j" $IN_M2S_MEM | grep "Evictions" | sed "s;Evictions = \(.*\);\1;")
		    env printf "                <stat name=\"conflicts\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    m2s_data=$(grep -A 52 "mod-x86-il1-$j" $IN_M2S_MEM | grep "^Prefetches" | sed "s;Prefetches = \(.*\);\1;")
		    env printf "                <stat name=\"prefetch_buffer_accesses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
		    env printf "            </component>\n" >> $OUT_XML

			#-----------------------------------------
			#Core0 Data Translation Lookaside Buffer
			#-----------------------------------------
			#no stats provided in M2S
			#!!FIXME - approximated by using data-cache accesses/misses/evictions
			    env printf "            <component id=\"system.core$j.dtlb\" name=\"dtlb\">\n" >> $OUT_XML
			    env printf "                <param name=\"number_entries\" value=\"256\"/>\n" >> $OUT_XML
				m2s_data=$(grep -A 15 "mod-x86-l1-$j" $IN_M2S_MEM | grep "Accesses" | sed "s;Accesses = \(.*\);\1;")
			    env printf "                <stat name=\"total_accesses\" value=\"%s\"/><!-- ^ -->\n" $m2s_data >> $OUT_XML
			    m2s_data=$(grep -A 15 "mod-x86-l1-$j" $IN_M2S_MEM | grep "Misses" | sed "s;Misses = \(.*\);\1;")
				env printf "                <stat name=\"total_misses\" value=\"%s\"/><!-- ^ -->\n" $m2s_data >> $OUT_XML
				m2s_data=$(grep -A 15 "mod-x86-l1-$j" $IN_M2S_MEM | grep "Evictions" | sed "s;Evictions = \(.*\);\1;")
			    env printf "                <stat name=\"conflicts\" value=\"%s\"/><!-- ^ -->\n" $m2s_data >> $OUT_XML
			    env printf "            </component>\n" >> $OUT_XML
			
			#-----------------------------
			#Core0 Data Cache - multiple caches
			#-----------------------------
			    env printf "            <component id=\"system.core$j.dcache\" name=\"dcache\">\n" >> $OUT_XML
			    sets=$(grep -A 52 "mod-x86-l1-$j" $IN_M2S_MEM | grep "Sets" | sed "s;Sets = \(.*\);\1;")
			    assoc=$(grep -A 52 "mod-x86-l1-$j" $IN_M2S_MEM | grep "Assoc" | sed "s;Assoc = \(.*\);\1;")
			    bSize=$(grep -A 52 "mod-x86-l1-$j" $IN_M2S_MEM | grep "BlockSize" | sed "s;BlockSize = \(.*\);\1;")
			    lat=$(grep -A 52 "mod-x86-l1-$j" $IN_M2S_MEM | grep "Latency" | sed "s;Latency = \(.*\);\1;")
			    size=$(( sets * assoc * bSize ))

			    printf "L1-DCache-$j\n-------------\nSize: $size\n# Sets: $sets\nAssoc: $assoc\nBlk Size: $bSize\n"

 			   #still need params: bank (1), throughput wrt core clk (3), output width (16)
			    env printf "                <param name=\"dcache_config\" value=\"%i,%s,%s,1, 4,%s, 32,1 \"/>\n" $size $bSize $assoc $lat >> $OUT_XML
			    #<!-- the parameters are: capacity,
				#						 block_width, 
				#						 associativity, 
				#						 bank, 
				#						 throughput w.r.t. core clock, 
				#						 latency w.r.t. core clock,
				#						 output_width, 
				#						 cache policy,  
				#						 -->
		 	    #<!-- cache_policy : 
				#			0 no write or write-though with non-write allocate
				#			1 write-back with write-allocate 
				#			-->
			    env printf "                <param name=\"buffer_sizes\" value=\"16, 16, 16, 16\"/>\n" >> $OUT_XML

			    m2s_data=$(grep -A 52 "mod-x86-l1-$j" $IN_M2S_MEM | grep -m 1 "Reads" | sed "s;Reads = \(.*\);\1;")
			    env printf "                <stat name=\"read_accesses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
			    m2s_data=$(grep -A 52 "mod-x86-l1-$j" $IN_M2S_MEM | grep -m 1 "Writes" | sed "s;Writes = \(.*\);\1;")
			    env printf "                <stat name=\"write_accesses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
			    m2s_data=$(grep -A 52 "mod-x86-l1-$j" $IN_M2S_MEM | grep -m 1 "ReadMisses" | sed "s;ReadMisses = \(.*\);\1;")
			    env printf "                <stat name=\"read_misses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
			    m2s_data=$(grep -A 52 "mod-x86-l1-$j" $IN_M2S_MEM | grep -m 1 "WriteMisses" | sed "s;WriteMisses = \(.*\);\1;")
			    env printf "                <stat name=\"write_misses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
			    m2s_data=$(grep -A 52 "mod-x86-l1-$j" $IN_M2S_MEM | grep -m 1 "Evictions" | sed "s;Evictions = \(.*\);\1;")
			    env printf "                <stat name=\"conflicts\" value=\"%i\"/><!-- * -->\n" $m2s_data >> $OUT_XML
			    env printf "            </component>\n" >> $OUT_XML

				#--------------------------------------
			    #Core0 Branch Target Buffer
				#--------------------------------------		
				# Num BTB's usually matches num threads & instr fetch ports
			    env printf "            <param name=\"number_of_BTB\" value=\"2\"/>\n" >> $OUT_XML
			    env printf "            <component id=\"system.core$j.BTB\" name=\"BTB\">\n" >> $OUT_XML

			    #Hard to tell from M2S data				  - WAS:5120,4,2,1, 1,3
			    env printf "                <param name=\"BTB_config\" value=\"4096,4,2,1,1,4\"/>\n" >> $OUT_XML
			    #<!-- the parameters are capacity,block_width,associativity,bank, throughput w.r.t. 
				#core clock, latency w.r.t. core clock,--	>

   
				#FIXME this snippet could be used to update script to handle multithreaded case.
				#       right now it's here to get accurate values from M2S results 
				core="c$j"
				thd="t0"
				coreThd=$core$thd
                     
			    m2s_data=$(grep -A 300 "$coreThd" $IN_M2S_CPU | grep  -m 1 "BTB.Reads" | sed "s;BTB.Reads = \(.*\);\1;")
			    env printf "                <stat name=\"read_accesses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
			    m2s_data=$(grep -A 300 "$coreThd" $IN_M2S_CPU | grep  -m 1 "BTB.Writes"  | sed "s;BTB.Writes = \(.*\);\1;")
			    env printf "                <stat name=\"write_accesses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
			    env printf "            </component>\n" >> $OUT_XML

    env printf "        </component>\n" >> $OUT_XML
done


#end of core definition
#end for loop (HETERO CORES)





########################
#System
########################

#L1 & L2 Directory Tables
#
#		These counts are not used in M2S so
#		they are not imported by this script

#L1 Directory Table
#
env printf "        <component id=\"system.L1Directory0\" name=\"L1Directory0\">\n" >> $OUT_XML
env printf "            <param name=\"Directory_type\" value=\"0\"/>\n" >> $OUT_XML
env printf "            <param name=\"Dir_config\" value=\"4096,2,0,1,100,100, 8\"/>\n" >> $OUT_XML
env printf "            <param name=\"buffer_sizes\" value=\"8, 8, 8, 8\"/>\n" >> $OUT_XML
env printf "            <param name=\"clockrate\" value=\"3400\"/>\n" >> $OUT_XML
env printf "            <param name=\"ports\" value=\"1,1,1\"/>\n" >> $OUT_XML
env printf "            <param name=\"device_type\" value=\"0\"/>\n" >> $OUT_XML
env printf "            <stat name=\"read_accesses\" value=\"0\"/>\n" >> $OUT_XML
env printf "            <stat name=\"write_accesses\" value=\"0\"/>\n" >> $OUT_XML
env printf "            <stat name=\"read_misses\" value=\"0\"/>\n" >> $OUT_XML
env printf "            <stat name=\"write_misses\" value=\"0\"/>\n" >> $OUT_XML
env printf "            <stat name=\"conflicts\" value=\"0\"/>\n" >> $OUT_XML
env printf "        </component>\n" >> $OUT_XML

#L2 Directory Table
#
env printf "        <component id=\"system.L2Directory0\" name=\"L2Directory0\">\n" >> $OUT_XML
env printf "            <param name=\"Directory_type\" value=\"1\"/>\n" >> $OUT_XML
env printf "            <param name=\"Dir_config\" value=\"1048576,16,16,1,2, 100\"/>\n" >> $OUT_XML
env printf "            <param name=\"buffer_sizes\" value=\"8, 8, 8, 8\"/>\n" >> $OUT_XML
env printf "            <param name=\"clockrate\" value=\"3400\"/>\n" >> $OUT_XML
env printf "            <param name=\"ports\" value=\"1,1,1\"/>\n" >> $OUT_XML
env printf "            <param name=\"device_type\" value=\"0\"/>\n" >> $OUT_XML
env printf "            <stat name=\"read_accesses\" value=\"0\"/>\n" >> $OUT_XML
env printf "            <stat name=\"write_accesses\" value=\"0\"/>\n" >> $OUT_XML
env printf "            <stat name=\"read_misses\" value=\"0\"/>\n" >> $OUT_XML
env printf "            <stat name=\"write_misses\" value=\"0\"/>\n" >> $OUT_XML
env printf "            <stat name=\"conflicts\" value=\"0\"/>\n" >> $OUT_XML
env printf "        </component>\n" >> $OUT_XML

#------------------------
#L2 Cache
#------------------------

for k in $(seq 0 $((numL2s - 1)))
do
    env printf "        <component id=\"system.L2%i\" name=\"L2%i\">\n" $k $k >> $OUT_XML

    sets=$(grep -A 52 "mod-x86-l2-$k" $IN_M2S_MEM | grep "Sets" | sed "s;Sets = \(.*\);\1;")
    assoc=$(grep -A 52 "mod-x86-l2-$k" $IN_M2S_MEM | grep "Assoc" | sed "s;Assoc = \(.*\);\1;")
    bSize=$(grep -A 52 "mod-x86-l2-$k" $IN_M2S_MEM | grep "BlockSize" | sed "s;BlockSize = \(.*\);\1;")
    lat=$(grep -A 52 "mod-x86-l2-$k" $IN_M2S_MEM | grep "Latency" | sed "s;Latency = \(.*\);\1;")    
    size=$(( sets * assoc * bSize ))

    printf "L2-Cache-$k\n-------------\nSize: $size\n# Sets: $sets\nAssoc: $assoc\nBlk Size: $bSize\n"

    env printf "            <param name=\"L2_config\" value=\"%i,%s, %s, 1, 23, %s, 32, 1\"/><!-- * -->\n" $size $bSize $assoc $lat >> $OUT_XML
	#<!-- parameters: 
	#					capacity,
	#					block_width, 
	#					associativity, 
	#					bank, 
	#					throughput w.r.t. core clock, 
	#					latency w.r.t. core clock,
	#					output_width, 
	#					cache policy 
	#					-->

    env printf "            <param name=\"buffer_sizes\" value=\"16, 16, 16, 16\"/>\n" >> $OUT_XML
    env printf "            <param name=\"clockrate\" value=\"2700\"/>\n" >> $OUT_XML
    env printf "            <param name=\"ports\" value=\"1,1,1\"/>\n" >> $OUT_XML
    env printf "            <param name=\"device_type\" value=\"0\"/>\n" >> $OUT_XML

    m2s_data=$(grep -A 52 "mod-x86-l2-$k" $IN_M2S_MEM | grep -m 1 "Reads" | sed "s;Reads = \(.*\);\1;")    
    env printf "            <stat name=\"read_accesses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
    m2s_data=$(grep -A 52 "mod-x86-l2-$k" $IN_M2S_MEM | grep -m 1 "Writes" | sed "s;Writes = \(.*\);\1;")    
    env printf "            <stat name=\"write_accesses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
    m2s_data=$(grep -A 52 "mod-x86-l2-$k" $IN_M2S_MEM | grep -m 1 "ReadMisses" | sed "s;ReadMisses = \(.*\);\1;")    
    env printf "            <stat name=\"read_misses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
    m2s_data=$(grep -A 52 "mod-x86-l2-$k" $IN_M2S_MEM | grep -m 1 "WriteMisses" | sed "s;WriteMisses = \(.*\);\1;")    
    env printf "            <stat name=\"write_misses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
    m2s_data=$(grep -A 52 "mod-x86-l2-$k" $IN_M2S_MEM | grep -m 1 "Evictions" | sed "s;Evictions = \(.*\);\1;")
    env printf "            <stat name=\"conflicts\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
    env printf "            <stat name=\"duty_cycle\" value=\"1.0\"/>\n" >> $OUT_XML
    env printf "        </component>\n" >> $OUT_XML

done

#--------------------------------
#L3 Cache (If Any)
#--------------------------------

reset_stats $sets
#

if [ $numL3s -ne 0 ]
then
    for k in $(seq 0 $numL3s)
    do
        env printf "        <component id=\"system.L3%i\" name=\"L3%i\">\n" $k $k >> $OUT_XML
        sets=$(grep -A 52 "mod-x86-l3-$k" $IN_M2S_MEM | grep "Sets" | sed "s;Sets = \(.*\);\1;")
        assoc=$(grep -A 52 "mod-x86-l3-$k" $IN_M2S_MEM | grep "Assoc" | sed "s;Assoc = \(.*\);\1;")
        bSize=$(grep -A 52 "mod-x86-l3-$k" $IN_M2S_MEM | grep "BlockSize" | sed "s;BlockSize = \(.*\);\1;")
        lat=$(grep -A 52 "mod-x86-l3-$k" $IN_M2S_MEM | grep "Latency" | sed "s;Latency = \(.*\);\1;")    
        size=$(( sets * assoc * bSize ))
        env printf "            <param name=\"L3_config\" value=\"%i,%s, %s, %i, 8, %s, 32, 1\"/>\n" $size $bSize $assoc $k $lat >> $OUT_XML

		#<!-- parameters: 
		#					capacity,
		#					block_width, 
		#					associativity, 
		#					bank, 
		#					throughput w.r.t. core clock, 
		#					latency w.r.t. core clock,
		#					output_width, 
		#					cache policy 
		#					-->

        env printf "            <param name=\"buffer_sizes\" value=\"16, 16, 16, 16\"/>\n" >> $OUT_XML
        env printf "            <param name=\"clockrate\" value=\"3900\"/>\n" >> $OUT_XML
        env printf "            <param name=\"ports\" value=\"1,1,1\"/>\n" >> $OUT_XML
        env printf "            <param name=\"device_type\" value=\"0\"/>\n" >> $OUT_XML

        m2s_data=$(grep -A 52 "mod-x86-l3-$k" $IN_M2S_MEM | grep -m 1 "Reads" | sed "s;Reads = \(.*\);\1;")    
        env printf "            <stat name=\"read_accesses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
        m2s_data=$(grep -A 52 "mod-x86-l3-$k" $IN_M2S_MEM | grep -m 1 "Writes" | sed "s;Writes = \(.*\);\1;")    
        env printf "            <stat name=\"write_accesses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
        m2s_data=$(grep -A 52 "mod-x86-l3-$k" $IN_M2S_MEM | grep -m 1 "ReadMisses" | sed "s;ReadMisses = \(.*\);\1;")    
        env printf "            <stat name=\"read_misses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
        m2s_data=$(grep -A 52 "mod-x86-l3-$k" $IN_M2S_MEM | grep -m 1 "WriteMisses" | sed "s;WriteMisses = \(.*\);\1;")    
        env printf "            <stat name=\"write_misses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
        nrrm=$(grep -A 52 "mod-x86-l3-$k" $IN_M2S_MEM | grep -m 1 "NoRetryReadMisses" | sed "s;NoRetryReadMisses = \(.*\);\1;")
        nrwm=$(grep -A 52 "mod-x86-l3-$k" $IN_M2S_MEM | grep -m 1 "NoRetryWriteMisses" | sed "s;NoRetryWriteMisses = \(.*\);\1;")
        m2s_data=$(( nrrm + nrwm ))
        env printf "            <stat name=\"conflicts\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
        env printf "            <stat name=\"duty_cycle\" value=\"1.0\"/>\n" >> $OUT_XML
        env printf "        </component>\n" >> $OUT_XML
    done
else
    env printf "        <component id=\"system.L30\" name=\"L30\">\n" >> $OUT_XML
    env printf "            <param name=\"L3_config\" value=\"16777216,64,16, 16, 16, 100,1\"/>\n" >> $OUT_XML

	#<!-- parameters: 
	#					capacity,
	#					block_width, 
	#					associativity, 
	#					bank, 
	#					throughput w.r.t. core clock, 
	#					latency w.r.t. core clock,
	#					output_width, 
	#					cache policy 
	#					-->

    env printf "            <param name=\"clockrate\" value=\"0\"/>\n" >> $OUT_XML
    env printf "            <param name=\"ports\" value=\"1,1,1\"/>\n" >> $OUT_XML
    env printf "            <param name=\"device_type\" value=\"0\"/>\n" >> $OUT_XML
    env printf "            <param name=\"buffer_sizes\" value=\"16, 16, 16, 16\"/>\n" >> $OUT_XML
    env printf "            <stat name=\"read_accesses\" value=\"0\"/>\n" >> $OUT_XML
    env printf "            <stat name=\"write_accesses\" value=\"0\"/>\n" >> $OUT_XML
    env printf "            <stat name=\"read_misses\" value=\"0\"/>\n" >> $OUT_XML
    env printf "            <stat name=\"write_misses\" value=\"0\"/>\n" >> $OUT_XML
    env printf "            <stat name=\"conflicts\" value=\"0\"/>\n" >> $OUT_XML
    env printf "            <stat name=\"duty_cycle\" value=\"0.0\"/>\n" >> $OUT_XML
    env printf "        </component>\n" >> $OUT_XML

fi

#Interconnect Network
#Will need different NOCs (NoC0,NoC1,...) depending on Mem hierarchy and core interconnects
#(HETERO)
#
#NET L1-L2-0
#
env printf "        <component id=\"system.NoC0\" name=\"noc\">\n" >> $OUT_XML
env printf "            <param name=\"clockrate\" value=\"3400\"/>\n" >> $OUT_XML
env printf "            <param name=\"type\" value=\"0\"/>\n" >> $OUT_XML
env printf "            <param name=\"horizontal_nodes\" value=\"1\"/>\n" >> $OUT_XML
env printf "            <param name=\"vertical_nodes\" value=\"1\"/>\n" >> $OUT_XML
env printf "            <param name=\"has_global_link\" value=\"0\"/>\n" >> $OUT_XML
env printf "            <param name=\"link_throughput\" value=\"1\"/>\n" >> $OUT_XML
env printf "            <param name=\"link_latency\" value=\"1\"/>\n" >> $OUT_XML
env printf "            <param name=\"input_ports\" value=\"1\"/>\n" >> $OUT_XML
env printf "            <param name=\"output_ports\" value=\"1\"/>\n" >> $OUT_XML
env printf "            <param name=\"flit_bits\" value=\"256\"/>\n" >> $OUT_XML
env printf "            <param name=\"chip_coverage\" value=\"1\"/>\n" >> $OUT_XML
env printf "            <param name=\"link_routing_over_percentage\" value=\"0.5\"/>\n" >> $OUT_XML
m2s_data=$(grep -A 10 "Network.net-l1-l2-0.General" $IN_M2S_MEM | grep -m 1 "Transfers" | sed "s;Transfers = \(.*\);\1;")  
env printf "            <stat name=\"total_accesses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
env printf "        </component>\n" >> $OUT_XML

#
#NET L2->MM
#
env printf "        <component id=\"system.NoC1\" name=\"noc\">\n" >> $OUT_XML
env printf "            <param name=\"clockrate\" value=\"3400\"/>\n" >> $OUT_XML
env printf "            <param name=\"type\" value=\"0\"/>\n" >> $OUT_XML
env printf "            <param name=\"horizontal_nodes\" value=\"1\"/>\n" >> $OUT_XML
env printf "            <param name=\"vertical_nodes\" value=\"1\"/>\n" >> $OUT_XML
env printf "            <param name=\"has_global_link\" value=\"0\"/>\n" >> $OUT_XML
env printf "            <param name=\"link_throughput\" value=\"1\"/>\n" >> $OUT_XML
env printf "            <param name=\"link_latency\" value=\"1\"/>\n" >> $OUT_XML
env printf "            <param name=\"input_ports\" value=\"1\"/>\n" >> $OUT_XML
env printf "            <param name=\"output_ports\" value=\"1\"/>\n" >> $OUT_XML
env printf "            <param name=\"flit_bits\" value=\"256\"/>\n" >> $OUT_XML
env printf "            <param name=\"chip_coverage\" value=\"1\"/>\n" >> $OUT_XML
env printf "            <param name=\"link_routing_over_percentage\" value=\"0.5\"/>\n" >> $OUT_XML
m2s_data=$(grep -A 10 "Network.net-l2-mm.General" $IN_M2S_MEM | grep -m 1 "Transfers" | sed "s;Transfers = \(.*\);\1;")  
env printf "            <stat name=\"total_accesses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
env printf "        </component>\n" >> $OUT_XML
#System Memory
#env printf "        <component id=\"system.mem\" name=\"mem\">\n" >> $OUT_XML
#env printf "            <param name=\"mem_tech_node\" value=\"32\"/>\n" >> $OUT_XML
#env printf "            <param name=\"device_clock\" value=\"200\"/>\n" >> $OUT_XML
#env printf "            <param name=\"peak_transfer_rate\" value=\"6400\"/>\n" >> $OUT_XML
#env printf "            <param name=\"internal_prefetch_of_DRAM_chip\" value=\"4\"/>\n" >> $OUT_XML
#env printf "            <param name=\"capacity_per_channel\" value=\"4096\"/>\n" >> $OUT_XML
#env printf "            <param name=\"number_ranks\" value=\"2\"/>\n" >> $OUT_XML
#env printf "            <param name=\"num_banks_of_DRAM_chip\" value=\"8\"/>\n" >> $OUT_XML
#env printf "            <param name=\"Block_width_of_DRAM_chip\" value=\"64\"/>\n" >> $OUT_XML
#env printf "            <param name=\"output_width_of_DRAM_chip\" value=\"8\"/>\n" >> $OUT_XML
#env printf "            <param name=\"page_size_of_DRAM_chip\" value=\"8\"/>\n" >> $OUT_XML
#env printf "            <param name=\"burstlength_of_DRAM_chip\" value=\"8\"/>\n" >> $OUT_XML
#m2s_data=$(grep -A 15 "mod-x86-mm" $IN_M2S_MEM | grep -m 1 "Accesses" | sed "s;Accesses = \(.*\);\1;")
#env printf "            <stat name=\"memory_accesses\" value=\"%s\"/>\n" $m2s_data >> $OUT_XML
#m2s_data=$(grep -A 20 "mod-x86-mm" $IN_M2S_MEM | grep -m 1 "Reads" | sed "s;Reads = \(.*\);\1;")
#env printf "            <stat name=\"memory_reads\" value=\"%s\"/>\n" $m2s_data >> $OUT_XML
#m2s_data=$(grep -A 30 "mod-x86-mm" $IN_M2S_MEM | grep -m 1 "Writes" | sed "s;Writes = \(.*\);\1;")
#env printf "            <stat name=\"memory_writes\" value=\"%s\"/>\n" $m2s_data >> $OUT_XML
#env printf "        </component>\n" >> $OUT_XML

#Mem Controller
env printf "        <component id=\"system.mc\" name=\"mc\">\n" >> $OUT_XML
env printf "            <param name=\"type\" value=\"0\"/>\n" >> $OUT_XML
env printf "            <param name=\"mc_clock\" value=\"200\"/>\n" >> $OUT_XML

env printf "		    <param name=\"vdd\" value=\"0\"/>\n" >> $OUT_XML

env printf "            <param name=\"peak_transfer_rate\" value=\"3200\"/>\n" >> $OUT_XML
env printf "            <param name=\"block_size\" value=\"64\"/>\n" >> $OUT_XML
env printf "            <param name=\"number_mcs\" value=\"1\"/>\n" >> $OUT_XML
env printf "            <param name=\"memory_channels_per_mc\" value=\"1\"/>\n" >> $OUT_XML
env printf "            <param name=\"number_ranks\" value=\"2\"/>\n" >> $OUT_XML
env printf "            <param name=\"withPHY\" value=\"0\"/>\n" >> $OUT_XML
env printf "            <param name=\"req_window_size_per_channel\" value=\"32\"/>\n" >> $OUT_XML
env printf "            <param name=\"IO_buffer_size_per_channel\" value=\"32\"/>\n" >> $OUT_XML
env printf "            <param name=\"databus_width\" value=\"128\"/>\n" >> $OUT_XML
env printf "            <param name=\"addressbus_width\" value=\"51\"/>\n" >> $OUT_XML
m2s_data=$(grep -A 15 "mod-x86-mm" $IN_M2S_MEM | grep -m 1 "Accesses" | sed "s;Accesses = \(.*\);\1;")
env printf "            <stat name=\"memory_accesses\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
m2s_data=$(grep -A 20 "mod-x86-mm" $IN_M2S_MEM | grep -m 1 "Reads" | sed "s;Reads = \(.*\);\1;")
env printf "            <stat name=\"memory_reads\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
m2s_data=$(grep -A 30 "mod-x86-mm" $IN_M2S_MEM | grep -m 1 "Writes" | sed "s;Writes = \(.*\);\1;")
env printf "            <stat name=\"memory_writes\" value=\"%s\"/><!-- * -->\n" $m2s_data >> $OUT_XML
env printf "        </component>\n" >> $OUT_XML

#---------------------------------
# Ethernet, Pcix and flash aren't
# modeled in M2S
#---------------------------------
#On ship ethernet NIC
env printf "        <component id=\"system.niu\" name=\"niu\">\n" >> $OUT_XML
env printf "            <param name=\"type\" value=\"0\"/>\n" >> $OUT_XML
env printf "            <param name=\"clockrate\" value=\"350\"/>\n" >> $OUT_XML
env printf "            <param name=\"number_units\" value=\"0\"/>\n" >> $OUT_XML
env printf "            <stat name=\"duty_cycle\" value=\"1.0\"/>\n" >> $OUT_XML
env printf "            <stat name=\"total_load_perc\" value=\"0.7\"/>\n" >> $OUT_XML
env printf "        </component>\n" >> $OUT_XML

#PCIExpress
env printf "        <component id=\"system.pcie\" name=\"pcie\">\n" >> $OUT_XML
env printf "            <param name=\"type\" value=\"0\"/>\n" >> $OUT_XML
env printf "            <param name=\"withPHY\" value=\"1\"/>\n" >> $OUT_XML
env printf "            <param name=\"clockrate\" value=\"350\"/>\n" >> $OUT_XML
env printf "            <param name=\"number_units\" value=\"0\"/>\n" >> $OUT_XML
env printf "            <param name=\"num_channels\" value=\"8\"/>\n" >> $OUT_XML
env printf "            <stat name=\"duty_cycle\" value=\"1.0\"/>\n" >> $OUT_XML
env printf "            <stat name=\"total_load_perc\" value=\"0.7\"/>\n" >> $OUT_XML
env printf "        </component>\n" >> $OUT_XML

#Flash Memory
env printf "        <component id=\"system.flashc\" name=\"flashc\">\n" >> $OUT_XML
env printf "            <param name=\"number_flashcs\" value=\"0\"/>\n" >> $OUT_XML
env printf "            <param name=\"type\" value=\"1\"/>\n" >> $OUT_XML
env printf "            <param name=\"peak_transfer_rate\" value=\"200\"/>\n" >> $OUT_XML
env printf "            <stat name=\"duty_cycle\" value=\"1.0\"/>\n" >> $OUT_XML
env printf "            <stat name=\"total_load_perc\" value=\"0.7\"/>\n" >> $OUT_XML
env printf "        </component>\n" >> $OUT_XML

env printf "    </component>\n" >> $OUT_XML
env printf "</component>\n" >> $OUT_XML

env printf "*******************************************************\n"
env printf " Conversion Complete - %s\n" $3
env printf "*******************************************************\n"
env printf "\n"

#/////////////////////////////
