#!/bin/sh -l

echo "**********************************************"
echo "TSQLLint by Nathan Boyd - https://git.io/JILDv"
echo "**********************************************"

if [ -z "$3" ]
    then 
        echo "No config file found, using defaults."
        tsqllint $1 $2
    else
        echo "Using config file $3"
        tsqllint $1 $2 -c $3
fi