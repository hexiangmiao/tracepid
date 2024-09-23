#!/bin/bash

#[[ $1 ~= '^[[digit]+]$' ]] && echo "Number correct" || echo "We need pure number";exit 1


function isRuning(){
	if [ $1 == "pid" ] ; then
		temp=$(ps -ef | awk -v p=$2 '$2==p{print $0}')
		if [ -z "$temp" ] ; then
			echo "$pid is not running anymore"
			return 1
		else
			echo "Running"
			return 0
		fi
	fi

	if [ $1 == "ppid" ] ; then
		temp=$(ps -ef | awk -v p=$2 '$3==p{print $0}')
		if [ -z "$temp" ] ; then
			echo "$pid is not running anymore"
			return 1
		else
			echo "Running"
			return 0
		fi
	fi
}


function logpid(){
    ft=$(date "+%Y%m%d-%H:%M:%S")
    ps -ef | awk -v p=$1 '$2==p{print $0}'| sed "s/^/$ft null /g" >> trace.log
}



if [ $# != 1 ] ; then
	echo "We need a pid number"
	exit 1
fi

# The pid should be a running ppid(not pid)
#if ! isRuning ppid $1 ; then
#	echo "The $1 is not a valid PPID"
#	exit 1
#fi

# Housekeeping
# all.pid 
#    is used to store all pids which are the children of pid provided as the $1 of this script 
#    it will also store all children of childrend of $1 and move forward untial pid has no children
# trace.log
#    act like a datebase that save records of all pids occuring in all.pid
#    this acts like a source for tool to generate the calling tree of $1
#    record schema like this : the first two time column is added by me and others are just copy from ps -ef command
#        pid-found-time pid-disappear-time uid pid ppid ....
#    

# overriten the file and only keep $1 pid as father of all
echo $1 > all.pid
# remove log file
rm trace.log
# record $1's record in trace.log
logpid $1

# A infinity loop so that we keep tracking all.pid util no record in all.pid which means $1 story is over
while true
do
    # A flog to show if all.pid is empty, if so, it will not go inside loop
    loopflag=false

    # Loop through all.pid for once
    for pid in $(cat all.pid)
    do
	loopflag=true
    	# Check if pid is ppid
    	temp1=$(ps -ef | awk -v p=$pid '$3==p{print $0}')
    	if [ -z "$temp1" ] ; then
    		echo "$pid is not PPID"
    	else
    		# Get all the pid's chirden pids and write them into all.pid
    		cpid=$(echo "$temp1" | awk '{print $2}')
    		# Check if pid already in the all.pid and only add entry when no record
    		for pid2 in $cpid
    		do
    			if grep $pid2 all.pid &>/dev/null ; then
    				echo "Has record"
    			else
    				echo "No record"
    				echo $pid2 >> all.pid
				# I only need to logpid only when new pid found
				logpid $pid2
    			fi
    		done
    	fi
    
    	# check if pid is a running pid otherwise we consider this pid has exited and need to remove it from all.pid
    	temp=$(ps -ef | awk -v p=$pid '$2==p{print $0}')
    	if [ -z "$temp" ] ; then
    		echo "$pid is not running anymore"
    		# Remove pid from all.pid
    		sed -i "/$pid/d" all.pid
    		# Update trace.log pid's ending time
		# To be done
    		dt=$(date "+%Y%m%d-%H:%M:%S")
		sed -i "s/null\( $USER      $pid\)/$dt\1/g" trace.log
    	else
    		echo "$pid is still Running, keep it in all.pid"
    	fi
    done

    # May or may not sleep
    sleep 5

    # check if all.pid is empty, if so, break the infinity loop and exit
    #
    #
    [ $loopflag == "false" ] && echo "No pid left to track, exiting..." && break

done
