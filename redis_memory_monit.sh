#!/bin/bash


if [ $# -ne 5 ]
then
echo "check input if maxmemory not set ./redismem.sh host port 0 wmem(mb) cmem(mb)"
echo "check input if maxmemory set ./redismem.sh host port 0 wmem%(mb) cmem%(mb)"
exit 0
fi


hst=$1
prt=$2
cnf=$3
auth=
wmem=$4
cmem=$5

checkredis=$(whereis redis-cli |awk '{print $2}' | tr -d ' ')

if [ -z "$checkredis" ]
then
echo "Rediscli is not available"
exit 1
fi


base=$($checkredis -h $hst -p $prt info 2>/dev/null)

if [ $? -ne 0 ]
then
echo "REDIS"""_"""$prt - This port is down!!"
exit 2
fi

if [ $cnf -eq 0 ]
then
wmaxmb=$(echo "$wmem/(1024*1024)" | bc)
cmaxmb=$(echo "$cmem/(1024*1024)" | bc)
usage=$(echo "$base" | grep 'used_memory_rss:' | awk -F":" '{print $2}' | tr -d '\015' | sed 's/^\n//g')
usagmb=$(echo "$usage/(1024*1024)" | bc)
        if [ $usagmb -gt $cmem ]
        then
        echo "REDIS"""_"""$prt - Redis Memory usage is Critial $usagmb (MB)"
        exit 2
        else
        echo "REDIS"""_"""$prt - Redis Memory usage is ok $usagmb (MB)"
        exit 0
        fi
fi

if [ $cnf -eq 1 ]
then
wmaxmb=$(echo "scale=2;$wmem/100" | bc)
cmaxmb=$(echo "scale=2;$cmem/100" | bc)
cmemt=$($checkredis -h $hst -p $prt config get maxmemory | awk 'NR==2{print $0}' | tr -d '"')
maxmb=$(echo "$cmemt/(1024*1024)" | bc)
usage=$(echo "$base" | grep 'used_memory_rss:' | awk -F":" '{print $2}' | tr -d '\015' | sed 's/^\n//g')
usagmb=$(echo "$usage/(1024*1024)" | bc )
crtic=$(echo "$maxmb*$cmaxmb" | bc | sed 's/\(.*\)\..*/\1/g')

        if [ $usagmb -gt $crtic ]
        then
        echo "REDIS"""_"""$prt - Redis Memory usage is Critial $usagmb (MB)"
        exit 2
        else
        echo "REDIS"""_"""$prt - Redis Memory usage is ok $usagmb (MB)"
        exit 0
        fi
fi
