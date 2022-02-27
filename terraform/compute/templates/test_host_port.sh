#!/bin/bash
if [ "$2" == "" ]; then
echo "Syntax: $0 <host> <port>"
exit;
fi

host=$1
port=$2

r=$(bash -c 'exec 3<> /dev/tcp/'$host'/'$port';echo $?' 2>/dev/null)
if [ "$r" = "0" ]; then
    echo "$host $port is open"
else
    echo "$host $port is closed"
    exit 1 # To force fail result in ShellScript
fi