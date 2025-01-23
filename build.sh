#!/bin/bash

rm -f build.bas
i=10

while read line; do
	line=$(echo $line | xargs)
	if [[ $line == "" ]]; then continue; fi
	if echo $line | grep "^rem"; then continue; fi
	echo "$i $line" >> build.bas
	i=$((i+10))
done < mutineers.bas
