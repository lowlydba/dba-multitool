#!/bin/sh -l

echo "**********************************************"
echo "✅ TSQLLint by Nathan Boyd - https://github.com/tsqllint/tsqllint"
echo "✅ TSQLLint Github Action by John McCall / lowlydba - https://github.com/lowlydba/tsqllint-action"
echo "**********************************************"

if [ -z "$2" ]
    then
        echo "No config file found, using defaults."
        tsqllint $1
    else
        echo "Using config file at $2"
        output=`tsqllint $1 -c $2 | tail -n4`
        echo "$output"
fi
