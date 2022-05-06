#!/bin/bash

# DESCRIPTION
#####################################################################
# This script is for automated submission of tinker dynamic jobs.   #
# It is intended to work with AMOEBAAnnihilator.                    #
# If using as intended, user needs to set:                          #
# - AMOEBAAnnihilator job file                                      #
# - list of nodes that can be used                                  #
# The script will:                                                  #
# - create my_jobs.txt from poltype jobfile (reformatting)          #
# - each line in my_jobs.txt is a job                               #
# - for each job,  script will check for available node             #
# - if it finds 1, will ssh to node and submit job w correct tinker #
# - job pid will be stored                                          #
# - if it does not find avail node, sleep 30 min and check again    #
# - it will also check status of pids                               #
# - when pid no longer running,    will be removed from list        #
# - after a job is submitted,    will proceed to the next line      #
#####################################################################

# FUNCTIONS
#####################################################################

# Name: FindNode
# How to run: FindNode "${node_list[@]}"
# Example output if found a node:
#    FALSE
#    bme-black /home/liuchw/Softwares/tinkers/Tinker9-latest/build_cuda11.2/tinker9
# Example output if no node free:
#    TRUE
function FindNode {
    local node_list=("$@")                  # Rebuild the array of nodes passed in
    #echo "${node_list[@]}"
    last_node="${node_list[@]:(-1)}"        # find last node in list
    #echo "the last node is $last_node"
    fancy_tinkergpu="/home/liuchw/Softwares/tinkers/Tinker9-latest/build_cuda11.2/tinker9"
    tinkergpu="/home/liuchw/Softwares/tinkers/Tinker9-latest/build_cuda10.2/tinker9"
    for ((i = 0 ; i<${#node_list[@]} ; i++)); do                         # for each node in list
        node="${node_list[$i]}"             # set $node to ith place in list
        #echo "Trying $node"
        #echo "i is $i"
        # ssh to node, run nvidia-smi to get info, look for line with cuda version, trim to only that
        cuda_version=$(ssh -n $node 'nvidia-smi | grep "CUDA Version:" | awk "{ print \$9 }"')
        #echo $cuda_version
        # ssh to node, run nvidia-smi, get lines mentioning tinker9, count them for num tinker jobs running
        jobs_running=$(ssh -n $node 'nvidia-smi | grep "tinker9" | awk "/tinker9/{count++} END{print count}"')
        #echo "there are $jobs_running jobs running"                     # blank if no jobs on node
        # ssh to node, run nvidia-smi, see if there are any lines saying no running processes found
        no_jobs_full=$(ssh -n $node 'nvidia-smi | grep "No running processes found"')
        no_jobs="$(echo $no_jobs_full | awk '{$1=$NF=""; print $0}')"    # use awk to trim line
        if [[ "$cuda_version" == "10.2" ]]; then
            #echo "$node is an older gpu"
            # if no other jobs, submit to this older gpu node
            if [[ "$no_jobs" == " No running processes found " ]]; then
                tinker=$tinkergpu
                local node_free="TRUE"
                nowhere_to_run="FALSE"
                #echo "$node is free"
                echo "$nowhere_to_run"      # function output line 1
                echo "$node $tinker"        # function output line 2
                return                      # can exit loop going over nodes bc found node
            else
                #echo "$node is not free."
                local node_free="FALSE"
                if [[ "$node" == "$last_node" ]]; then
                    #echo "last node in list not free"
                    nowhere_to_run="TRUE"
                    echo "$nowhere_to_run"  # function output 1st line
                    return                  # exit loop going over nodes bc none free now
                else
                    #echo "checking next node"
                    nowhere_to_run="FALSE"
                fi
            fi
        elif [[ "$cuda_version" == @(11.2|11.4) ]]; then
            #echo "$node is a fancy gpu"
            # if no other jobs, submit to this newer gpu node
            if [[ "$no_jobs" == "No running processes found" ]]; then
                tinker=$fancy_tinkergpu
                #echo "nothing running on $node right now"
                local node_free="TRUE"
                #echo "$node is free"
                nowhere_to_run="FALSE"
                echo "$nowhere_to_run"      # function output 1st line
                echo "$node $tinker"        # function output 2nd line
                return                      # can exit loop going over nodes bc found node
            # if only 1 other job, submit another to this newer gpu node
            elif [[ "$jobs_running" != @(2|3|4) ]]; then
                #echo "there are $jobs_running jobs running"            # blank if no jobs on node
                tinker=$fancy_tinkergpu
                #echo 'breaking out of newer gpu not 2 3 or 4 tinker jobs'
                nowhere_to_run="FALSE"
                echo "$nowhere_to_run"      # function output line 1
                echo "$node $tinker"        # function output line 2 - node + correct tinker
                return                      # can exit loop going over nodes bc found node
            else
                #echo "$node is not free."
                local node_free="FALSE"
                sleep 5
                if [[ "$node" == "$last_node" ]]; then
                    #echo "last node in list not free"
                    nowhere_to_run="TRUE"
                    echo "$nowhere_to_run"  # function output 1st line
                    return                  # exit loop going over nodes bc none free now
                else
                    #echo "checking next node"
                    nowhere_to_run="FALSE"
                fi
            fi
        #else
            #echo "no cuda possibly"
        fi
    done
}

# Name: PidStatus
# How to run: PidStatus "$pid"
# Example output if pid running:
#    1
# Example output if pid not running:
#    0
function PidStatus {
    local pid=$1
    if [ -n "$(ps -p $pid -o pid=)" ]; then
        #echo "$pid running"
        local pid_status="1"
    else
        #echo "$pid not running"
        local pid_status="0"
    fi
    #echo "$pid status $pid_status"
    echo "$pid_status"
}

#END OF FUNCTIONS

#####################################################################
# SET NODES
declare -a node_list=("node36" "node206" "bme-pluto" "bme-mars" "bme-venus")
#declare -a node_list=("bme-venus")                              # for testing with just 1 node
declare -a pids=()                                               # empty array for storing job pids


# CREATE FORMATTED JOB TEXT FILE
aa_jobfile=melk_04-25-22_proddynamicsjobs.txt                    # annihilator job file you are reading from
my_jobfile="my_jobs.txt"                                         # file that I am writing job info to
# take everything between "--job=" and "--numproc" in aa job file and write to my own job file
sed 's/.*--job=\(.*\)--numproc.*/\1/' ${aa_jobfile} > ${my_jobfile}
# delete first line of new job file in case annihilator submitted it already
#sed -i '1d' ${my_jobfile}
num_jobs=$(wc -l ${my_jobfile} | awk '{ print $1 }')
echo "There are ${num_jobs} jobs to run."

line_counter=0
# BEGIN MAIN
while IFS= read -r line; do                                      # for each line in my_jobs.txt
    echo "Starting on a new job."
    #echo "$line"                                                # print line
    # get info about job from its line in my_jobs.txt
    dir=$(echo $line | awk '{ print $2}')                        # get directory from job txt file
    #echo "dir is $dir"
    xyz=$(echo $line | grep -o "\S*xyz")                         # get xyz
    #echo "xyz is $xyz"
    key=$(echo $line | grep -o "\S*key")                         # get key
    #echo "key is $key"
    out_file=$(echo $line | grep -o "\S*out" )                   # get out
    #echo "out file is $out_file"
    nums=$(echo $line | sed 's/.*key\(.*\)>.*/\1/')              # steps tstep dump ensmbl temp pres
    tinker_cmd="dynamic"                                         # set desired tinker command: ex "dynamic" or "bar 1"
    # check to see if a node is free
    echo "Finding a node to run job on..."
    nowhere_to_run=$(FindNode "${node_list[@]}" | head -n 1)     # run FindNode and get nowhere_to_run - 1st line out
    echo "Nowhere to run = $nowhere_to_run"
    # should get out $nowhere_to_run \n $node $tinker
    if [[ "$nowhere_to_run" == "FALSE" ]]; then                  # there is a node available
        node_tinker=$(FindNode "${node_list[@]}" | awk 'NR==2')  # run FindNode - get node+correct tinker - 2nd line out
        #echo $node_tinker
        node=$(echo $node_tinker | awk '{ print $1}')            # 1st field of node_tinker is node
        tinker=$(echo $node_tinker | awk '{ print $2}')          # 2nd field is correct tinker for node cuda version
        echo "Submitting job to $node"
        cmd_str="$tinker_cmd $dir/$xyz -k $dir/$key $nums > $dir/$out_file"
        echo "ssh -n $node cd $dir ; nohup $tinker $cmd_str &"   # print job info
        $(ssh -n $node "cd $dir ; nohup $tinker $cmd_str &") &   # submit job
        pids+=( "$!" )                                           # add pid of most recent job to array
        echo "${pids[@]}"                                        # print array of pids
        sleep 120                                                # sleep 2 min - avoids some race conditions
    elif [[ "$nowhere_to_run" == "TRUE" ]]; then
        echo "No node free right now - going to keep checking..."
        sleep 15
        while [[ "$nowhere_to_run" == "TRUE" ]]; do
            #echo "Nowhere to run = $nowhere_to_run"
	        # run FindNode and get nowhere_to_run - 1st line of output, should exit loop if FALSE
            nowhere_to_run=$(FindNode "${node_list[@]}" | head -n 1)
            echo "Nowhere to run = $nowhere_to_run"
	        for pid in "${pids[@]}"; do                          # loop through array of pids
                pid_running=$(PidStatus "$pid")                  # check status of pid
		        echo "$pid status $pid_running"
	        done
	        sleep 1800                                           # sleep 30 min before checking again
        done
    	echo "Checking to see if any pids have finished..."
    	for pid in "${pids[@]}"; do                              # loop through array of pids
    	    pid_running=$(PidStatus "$pid")                      # check status of pid
    	    echo "$pid status $pid_running"
    	    if [[ "$pid_running" == "0" ]]; then                 # if pid is not running
    		    echo "Removing $pid from list."
    		    pids=( ${pids[@]/$pid} )                         # remove $pid from array
    		    sleep 5                                          # safety
    	    fi
        done
    	echo "List of pids is now: ${pids[@]}"                   # print new pid list
        echo "Trying to submit next job..."
        node_tinker=$(FindNode "${node_list[@]}" | awk 'NR==2')  # look for available node, choose correct tinker
        node=$(echo $node_tinker | awk '{ print $1}')
        tinker=$(echo $node_tinker | awk '{ print $2}')
        echo "Submitting job to $node"
        cmd_str="$tinker_cmd $dir/$xyz -k $dir/$key $nums > $dir/$out_file"
        echo "ssh -n $node cd $dir ; nohup $tinker $cmd_str &"   # print job info
        $(ssh -n $node "cd $dir ; nohup $tinker $cmd_str &") &   # submit job
        pids+=( "$!" )                                           # add pid of most recent job to array
        echo "${pids[@]}"                                        # print array of pids
        sleep 120                                                # sleep 2 min - avoids some race conditions
    fi
    line_counter=$((line_counter + 1))
    progress_perc=$(( 100* line_counter/num_jobs ))
    echo "${progress_perc} % of jobs have been submitted!"
done < ${my_jobfile}

echo "All jobs have been submitted! Yay!"
